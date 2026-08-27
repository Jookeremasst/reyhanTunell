package system

import (
	"fmt"
	"os"
)

func WriteUnit(path, content string) error {
	return os.WriteFile(path, []byte(content), 0644)
}

func DaemonReload() error {
	return Run("systemctl", "daemon-reload")
}

func EnableStart(service string) error {
	if err := Run("systemctl", "enable", "--now", service); err != nil {
		return err
	}

	return nil
}

func StopDisable(service string) error {
	_ = Run("systemctl", "disable", "--now", service)
	return nil
}

func Restart(service string) error {
	return Run("systemctl", "restart", service)
}

func Status(service string) error {
	return Run("systemctl", "status", service, "--no-pager")
}

func Logs(service string) error {
	return Run("journalctl", "-u", service, "-n", "100", "--no-pager")
}

func ServiceName(id string) string {
	return "reyhanTunell-" + id + ".service"
}

// SSH Tunnel
func Unit(
	id string,
	user string,
	host string,
	sshPort int,
	localPort int,
	remoteHost string,
	remotePort int,
	keyPath string,
) string {
	return fmt.Sprintf(`[Unit]
Description=reyhanTunell SSH Tunnel %s
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/ssh -N -T -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o StrictHostKeyChecking=accept-new -o BatchMode=yes -i %s -p %d -L 0.0.0.0:%d:%s:%d %s@%s
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
`,
		id,
		keyPath,
		sshPort,
		localPort,
		remoteHost,
		remotePort,
		user,
		host,
	)
}

// SOCKS5 Tunnel
func SOCKS5Unit(id string) string {
	return fmt.Sprintf(`[Unit]
Description=reyhanTunell SOCKS5 Tunnel %s
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/reyhanTunell socks5-run %s
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
`,
		id,
		id,
	)
}
