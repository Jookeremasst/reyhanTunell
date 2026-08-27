package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

const BaseDir = "/etc/reyhanTunell"
const TunnelDir = "/etc/reyhanTunell/tunnels"

func Ensure() error {
	return os.MkdirAll(TunnelDir, 0700)
}

func Path(id string) string {
	return filepath.Join(TunnelDir, id+".json")
}

func Save(id string, data any) error {
	if err := Ensure(); err != nil {
		return err
	}

	b, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(Path(id), b, 0600)
}

func Load(id string, target any) error {
	b, err := os.ReadFile(Path(id))
	if err != nil {
		return err
	}

	return json.Unmarshal(b, target)
}

func ListIDs() ([]string, error) {
	if err := Ensure(); err != nil {
		return nil, err
	}

	entries, err := os.ReadDir(TunnelDir)
	if err != nil {
		return nil, err
	}

	var out []string

	for _, e := range entries {
		if filepath.Ext(e.Name()) != ".json" {
			continue
		}

		id := e.Name()[:len(e.Name())-5]
		out = append(out, id)
	}

	return out, nil
}

func Remove(id string) error {
	return os.Remove(Path(id))
}

func ServicePath(id string) string {
	return filepath.Join(
		"/etc/systemd/system",
		"reyhanTunell-"+id+".service",
	)
}

func ValidateID(id string) error {
	if id == "" || filepath.Base(id) != id {
		return fmt.Errorf("invalid tunnel ID")
	}

	return nil
}
