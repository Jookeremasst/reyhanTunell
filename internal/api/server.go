package api

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/http"
	"os"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/config"
	"github.com/ReyhanTeam/reyhanTunell/internal/core"
	"github.com/ReyhanTeam/reyhanTunell/internal/system"
)

const (
	DefaultAddress = "127.0.0.1:8765"
	TokenPath      = "/etc/reyhanTunell/api.token"
)

type Server struct {
	Address string
	Token   string
}

func Start(address string) error {
	if address == "" {
		address = DefaultAddress
	}

	if !isLoopbackAddress(address) {
		return fmt.Errorf("API must bind to a loopback address: %s", address)
	}

	token, err := ensureToken()
	if err != nil {
		return err
	}

	s := &Server{Address: address, Token: token}
	return http.ListenAndServe(address, s.handler())
}

func (s *Server) handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/health", s.health)
	mux.HandleFunc("/api/v1/tunnels", s.tunnels)
	mux.HandleFunc("/api/v1/tunnels/", s.tunnel)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		if r.URL.Path != "/api/v1/health" && !s.authorized(r) {
			writeError(w, http.StatusUnauthorized, "unauthorized")
			return
		}
		mux.ServeHTTP(w, r)
	})
}

func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"ok": true, "service": "reyhanTunell", "api_version": "v1"})
}

func (s *Server) tunnels(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		items, err := core.List()
		if err != nil { writeError(w, http.StatusInternalServerError, err.Error()); return }
		writeJSON(w, http.StatusOK, map[string]any{"data": items})
	case http.MethodPost:
		var t core.Tunnel
		if err := decodeJSON(r, &t); err != nil { writeError(w, http.StatusBadRequest, err.Error()); return }
		if err := createOrUpdate(t); err != nil { writeError(w, http.StatusBadRequest, err.Error()); return }
		writeJSON(w, http.StatusCreated, t)
	default:
		writeError(w, http.StatusMethodNotAllowed, "method not allowed")
	}
}

func (s *Server) tunnel(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/tunnels/")
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) == 0 || parts[0] == "" { writeError(w, http.StatusBadRequest, "tunnel ID is required"); return }
	id := parts[0]
	if err := config.ValidateID(id); err != nil { writeError(w, http.StatusBadRequest, err.Error()); return }

	if len(parts) == 1 {
		switch r.Method {
		case http.MethodGet:
			t, err := core.Load(id); if err != nil { writeError(w, http.StatusNotFound, "tunnel not found"); return }
			t.Status, _ = core.Status(id)
			writeJSON(w, http.StatusOK, t)
		case http.MethodPut:
			var t core.Tunnel
			if err := decodeJSON(r, &t); err != nil { writeError(w, http.StatusBadRequest, err.Error()); return }
			t.ID = id
			if err := createOrUpdate(t); err != nil { writeError(w, http.StatusBadRequest, err.Error()); return }
			writeJSON(w, http.StatusOK, t)
		case http.MethodDelete:
			if err := remove(id); err != nil { writeError(w, http.StatusInternalServerError, err.Error()); return }
			w.WriteHeader(http.StatusNoContent)
		default:
			writeError(w, http.StatusMethodNotAllowed, "method not allowed")
		}
		return
	}

	if len(parts) != 2 || r.Method != http.MethodPost { writeError(w, http.StatusMethodNotAllowed, "method not allowed"); return }
	switch parts[1] {
	case "start":
		err := system.Run("systemctl", "start", system.ServiceName(id))
		writeActionResult(w, err, id, "started")
	case "stop":
		err := system.Run("systemctl", "stop", system.ServiceName(id))
		writeActionResult(w, err, id, "stopped")
	case "restart":
		err := system.Restart(system.ServiceName(id))
		writeActionResult(w, err, id, "restarted")
	case "status":
		status, err := core.Status(id)
		if err != nil && status != "inactive" { writeError(w, http.StatusInternalServerError, err.Error()); return }
		writeJSON(w, http.StatusOK, map[string]any{"id": id, "status": status})
	case "logs":
		out, err := system.Output("journalctl", "-u", system.ServiceName(id), "-n", "100", "--no-pager")
		if err != nil { writeError(w, http.StatusInternalServerError, err.Error()); return }
		writeJSON(w, http.StatusOK, map[string]any{"id": id, "logs": string(out)})
	default:
		writeError(w, http.StatusNotFound, "unknown tunnel action")
	}
}

func createOrUpdate(t core.Tunnel) error {
	if err := config.ValidateID(t.ID); err != nil { return err }
	t.Type = strings.ToLower(strings.TrimSpace(t.Type))
	if t.Type != "ssh" && t.Type != "socks5" { return fmt.Errorf("unsupported tunnel type: %s", t.Type) }
	if t.LocalPort < 1 || t.LocalPort > 65535 { return errors.New("invalid local port") }
	if t.RemotePort < 1 || t.RemotePort > 65535 { return errors.New("invalid remote port") }

	if t.Type == "ssh" {
		if t.User == "" || t.Host == "" || t.KeyPath == "" { return errors.New("SSH user, host and key_path are required") }
		if t.SSHPort < 1 || t.SSHPort > 65535 { return errors.New("invalid SSH port") }
	} else if t.RemoteHost == "" {
		return errors.New("SOCKS5 remote host is required")
	}

	if t.Status == "" { t.Status = "configured" }
	if err := config.Save(t.ID, t); err != nil { return err }

	var unit string
	if t.Type == "ssh" {
		unit = system.Unit(t.ID, t.User, t.Host, t.SSHPort, t.LocalPort, t.RemoteHost, t.RemotePort, t.KeyPath)
	} else {
		unit = system.SOCKS5Unit(t.ID)
	}
	if err := system.WriteUnit(config.ServicePath(t.ID), unit); err != nil { return err }
	return system.DaemonReload()
}

func remove(id string) error {
	if _, err := core.Load(id); err != nil { return err }
	_ = system.StopDisable(system.ServiceName(id))
	if err := os.Remove(config.ServicePath(id)); err != nil && !os.IsNotExist(err) { return err }
	if err := config.Remove(id); err != nil && !os.IsNotExist(err) { return err }
	return system.DaemonReload()
}

func ensureToken() (string, error) {
	if err := config.Ensure(); err != nil { return "", err }
	if b, err := os.ReadFile(TokenPath); err == nil && strings.TrimSpace(string(b)) != "" { return strings.TrimSpace(string(b)), nil }

	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil { return "", err }
	token := hex.EncodeToString(buf)
	if err := os.WriteFile(TokenPath, []byte(token+"\n"), 0600); err != nil { return "", err }
	return token, nil
}

func (s *Server) authorized(r *http.Request) bool {
	value := r.Header.Get("Authorization")
	return value == "Bearer "+s.Token
}

func isLoopbackAddress(address string) bool {
	host, _, err := net.SplitHostPort(address)
	if err != nil { return false }
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

func decodeJSON(r *http.Request, v any) error {
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	return decoder.Decode(v)
}

func writeActionResult(w http.ResponseWriter, err error, id, action string) {
	if err != nil { writeError(w, http.StatusInternalServerError, err.Error()); return }
	writeJSON(w, http.StatusOK, map[string]any{"id": id, "action": action, "ok": true})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]any{"error": message})
}
