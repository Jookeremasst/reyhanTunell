package ssh

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/config"
	"github.com/ReyhanTeam/reyhanTunell/internal/core"
	"github.com/ReyhanTeam/reyhanTunell/internal/system"
)

func AddInteractive() error {
	in := bufio.NewReader(os.Stdin)
	ask := func(label, def string) string {
		if def != "" { fmt.Printf("%s [%s]: ", label, def) } else { fmt.Printf("%s: ", label) }
		s, _ := in.ReadString('\n')
		s = strings.TrimSpace(s)
		if s == "" { return def }
		return s
	}

	id := ask("Tunnel ID", "")
	if err := config.ValidateID(id); err != nil { return err }

	user := ask("SSH User", "root")
	host := ask("SSH Host/IP", "")
	sshPort, err := strconv.Atoi(ask("SSH Port", "22"))
	if err != nil || sshPort < 1 || sshPort > 65535 { return fmt.Errorf("invalid SSH port") }

	localPort, err := strconv.Atoi(ask("Local Listen Port", "8443"))
	if err != nil || localPort < 1 || localPort > 65535 { return fmt.Errorf("invalid local port") }

	remoteHost := ask("Remote Host", "127.0.0.1")
	remotePort, err := strconv.Atoi(ask("Remote Port", strconv.Itoa(localPort)))
	if err != nil || remotePort < 1 || remotePort > 65535 { return fmt.Errorf("invalid remote port") }

	keyPath := ask("SSH Key Path", "/root/.ssh/reyhanTunell_ed25519")

	if host == "" { return fmt.Errorf("SSH host is required") }
	if _, err := os.Stat(keyPath); os.IsNotExist(err) {
		fmt.Println("Creating SSH key...")
		if err := generateKey(keyPath); err != nil { return err }
	}
	fmt.Println("Copying public key to remote server...")
	if err := copyKey(keyPath, user, host, sshPort); err != nil { return err }

	t := core.Tunnel{
		ID: id, Type: "ssh", User: user, Host: host, SSHPort: sshPort,
		LocalAddress: "0.0.0.0", LocalPort: localPort,
		RemoteHost: remoteHost, RemotePort: remotePort,
		KeyPath: keyPath, Status: "configured",
	}
	if err := config.Save(t.ID, t); err != nil { return err }

	unit := system.Unit(id, user, host, sshPort, localPort, remoteHost, remotePort, keyPath)
	if err := system.WriteUnit(config.ServicePath(id), unit); err != nil { return err }
	if err := system.DaemonReload(); err != nil { return err }
	if err := system.EnableStart(system.ServiceName(id)); err != nil { return err }

	fmt.Println("Tunnel created and started:", id)
	return nil
}

func generateKey(path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil { return err }
	cmd := exec.Command("ssh-keygen", "-t", "ed25519", "-f", path, "-N", "", "-C", "reyhanTunell")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func copyKey(keyPath, user, host string, port int) error {
	cmd := exec.Command("ssh-copy-id", "-i", keyPath+".pub", "-p", strconv.Itoa(port), user+"@"+host)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}
