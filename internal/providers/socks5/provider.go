package socks5

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/config"
	"github.com/ReyhanTeam/reyhanTunell/internal/core"
	"github.com/ReyhanTeam/reyhanTunell/internal/system"
)

func AddInteractive() error {
	in := bufio.NewReader(os.Stdin)

	ask := func(label, def string) string {
		if def != "" {
			fmt.Printf("%s [%s]: ", label, def)
		} else {
			fmt.Printf("%s: ", label)
		}

		s, _ := in.ReadString('\n')
		s = strings.TrimSpace(s)

		if s == "" {
			return def
		}

		return s
	}

	askPort := func(label, def string) (int, error) {
		value := ask(label, def)

		port, err := strconv.Atoi(value)
		if err != nil || port < 1 || port > 65535 {
			return 0, fmt.Errorf("invalid port: %s", value)
		}

		return port, nil
	}

	fmt.Println()
	fmt.Println("==============================================")
	fmt.Println("              SOCKS5 Tunnel")
	fmt.Println("==============================================")

	// Tunnel ID
	id := ask("Tunnel ID", "")

	if err := config.ValidateID(id); err != nil {
		return err
	}

	// Local SOCKS5 listener on Iran
	localAddress := ask(
		"Local Listen Address",
		"127.0.0.1",
	)

	localPort, err := askPort(
		"Local Listen Port",
		"8443",
	)
	if err != nil {
		return err
	}

	// Foreign SOCKS5 server
	remoteHost := ask(
		"Foreign SOCKS5 Server/IP",
		"",
	)

	if remoteHost == "" {
		return fmt.Errorf(
			"foreign SOCKS5 server is required",
		)
	}

	remotePort, err := askPort(
		"Foreign SOCKS5 Port",
		"8443",
	)
	if err != nil {
		return err
	}

	// SOCKS5 authentication
	username := ask(
		"SOCKS5 Username",
		"",
	)

	password := ""

	if username != "" {
		password = ask(
			"SOCKS5 Password",
			"",
		)
	}

	fmt.Println()
	fmt.Println("==============================================")
	fmt.Println("        SOCKS5 Tunnel Configuration")
	fmt.Println("==============================================")

	fmt.Println("ID:               ", id)
	fmt.Println("Type:              SOCKS5")
	fmt.Println(
		"Local Listen:      ",
		fmt.Sprintf("%s:%d", localAddress, localPort),
	)
	fmt.Println("Foreign Server:    ", remoteHost)
	fmt.Println("Foreign Port:      ", remotePort)

	if username != "" {
		fmt.Println("Authentication:     enabled")
	} else {
		fmt.Println("Authentication:     disabled")
	}

	fmt.Println("==============================================")

	confirm := ask(
		"Create tunnel? [Y/n]",
		"Y",
	)

	confirm = strings.ToLower(
		strings.TrimSpace(confirm),
	)

	if confirm != "y" && confirm != "yes" {
		fmt.Println("Cancelled.")
		return nil
	}

	t := core.Tunnel{
		ID:   id,
		Type: "socks5",

		LocalAddress: localAddress,
		LocalPort:    localPort,

		RemoteHost: remoteHost,
		RemotePort: remotePort,

		SOCKS5User: username,
		SOCKS5Pass: password,

		Status: "configured",
	}

	// Save tunnel configuration.
	if err := config.Save(t.ID, t); err != nil {
		return err
	}

	fmt.Println()
	fmt.Println("[INFO] SOCKS5 tunnel configuration saved.")

	// Create systemd service.
	unit := system.SOCKS5Unit(t.ID)

	servicePath := config.ServicePath(t.ID)

	if err := system.WriteUnit(servicePath, unit); err != nil {
		return fmt.Errorf(
			"write SOCKS5 systemd service: %w",
			err,
		)
	}

	fmt.Println("[INFO] Systemd service created:", system.ServiceName(t.ID))

	// Reload systemd.
	if err := system.DaemonReload(); err != nil {
		return fmt.Errorf(
			"systemd daemon-reload failed: %w",
			err,
		)
	}

	// Enable and start tunnel.
	if err := system.EnableStart(system.ServiceName(t.ID)); err != nil {
		return fmt.Errorf(
			"start SOCKS5 tunnel failed: %w",
			err,
		)
	}

	fmt.Println()
	fmt.Println("[INFO] SOCKS5 tunnel started.")
	fmt.Println(
		"[INFO] Local:",
		fmt.Sprintf("%s:%d", localAddress, localPort),
	)
	fmt.Println(
		"[INFO] Remote:",
		fmt.Sprintf("%s:%d", remoteHost, remotePort),
	)
	fmt.Println(
		"[INFO] Service:",
		system.ServiceName(t.ID),
	)

	return nil
}
