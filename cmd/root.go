package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/api"
	"github.com/ReyhanTeam/reyhanTunell/internal/core"
	"github.com/ReyhanTeam/reyhanTunell/internal/providers/socks5"
	"github.com/ReyhanTeam/reyhanTunell/internal/providers/ssh"
)

func Execute() {
	if len(os.Args) == 1 {
		menu()
		return
	}

	switch os.Args[1] {
	case "menu":
		menu()

	case "api":
		address := api.DefaultAddress
		if len(os.Args) >= 3 && strings.TrimSpace(os.Args[2]) != "" {
			address = os.Args[2]
		}
		if err := api.Start(address); err != nil {
			fmt.Println("Error:", err)
		}

	case "add":
		runAdd()

	case "socks5-run":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell socks5-run <id>")
			return
		}

		if err := socks5.Run(os.Args[2]); err != nil {
			fmt.Println("Error:", err)
		}

	case "list":
		list()

	case "status":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell status <id>")
			return
		}
		status(os.Args[2])

	case "start":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell start <id>")
			return
		}
		core.Start(os.Args[2])

	case "stop":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell stop <id>")
			return
		}
		core.Stop(os.Args[2])

	case "restart":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell restart <id>")
			return
		}
		core.Restart(os.Args[2])

	case "remove":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell remove <id>")
			return
		}
		core.Remove(os.Args[2])

	case "logs":
		if len(os.Args) < 3 {
			fmt.Println("Usage: reyhanTunell logs <id>")
			return
		}
		core.Logs(os.Args[2])

	case "version":
		fmt.Println("reyhanTunell v0.1.0")

	default:
		fmt.Println("Unknown command:", os.Args[1])
		fmt.Println("Use: reyhanTunell menu")
	}
}

func menu() {
	in := bufio.NewReader(os.Stdin)

	for {
		fmt.Println()
		fmt.Println("==============================================")
		fmt.Println("                 reyhanTunell")
		fmt.Println("==============================================")
		fmt.Println(" 1. Add Tunnel")
		fmt.Println(" 2. List All Tunnels")
		fmt.Println(" 3. Restart Tunnel")
		fmt.Println(" 4. Start Tunnel")
		fmt.Println(" 5. Stop Tunnel")
		fmt.Println(" 6. Tunnel Status")
		fmt.Println(" 7. Tunnel Logs")
		fmt.Println(" 8. Remove Tunnel")
		fmt.Println(" 0. Exit")
		fmt.Println("==============================================")

		fmt.Print("Please enter your selection [0-8]: ")

		s, _ := in.ReadString('\n')
		s = strings.TrimSpace(s)

		switch s {
		case "1":
			runAdd()

		case "2":
			list()

		case "3":
			chooseID("Restart", core.Restart)

		case "4":
			chooseID("Start", core.Start)

		case "5":
			chooseID("Stop", core.Stop)

		case "6":
			chooseID("Status", status)

		case "7":
			chooseID("Logs", core.Logs)

		case "8":
			chooseID("Remove", core.Remove)

		case "0":
			return

		default:
			fmt.Println("Invalid selection.")
		}
	}
}

func runAdd() {
	in := bufio.NewReader(os.Stdin)

	for {
		fmt.Println()
		fmt.Println("==============================================")
		fmt.Println("             Select Tunnel Type")
		fmt.Println("==============================================")
		fmt.Println(" 1. SSH")
		fmt.Println(" 2. SOCKS5")
		fmt.Println(" 3. OpenVPN")
		fmt.Println(" 4. WireGuard")
		fmt.Println(" 5. HTTP")
		fmt.Println(" 0. Back")
		fmt.Println("==============================================")

		fmt.Print("Select protocol [0-5]: ")

		s, _ := in.ReadString('\n')
		s = strings.TrimSpace(s)

		switch s {
		case "1":
			if err := ssh.AddInteractive(); err != nil {
				fmt.Println("Error:", err)
			}
			return

		case "2":
			if err := socks5.AddInteractive(); err != nil {
				fmt.Println("Error:", err)
			}
			return

		case "3":
			fmt.Println("OpenVPN provider is not implemented yet.")
			return

		case "4":
			fmt.Println("WireGuard provider is not implemented yet.")
			return

		case "5":
			fmt.Println("HTTP provider is not implemented yet.")
			return

		case "0":
			return

		default:
			fmt.Println("Invalid selection.")
		}
	}
}

func list() {
	items, err := core.List()
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	if len(items) == 0 {
		fmt.Println("No tunnels configured.")
		return
	}

	fmt.Printf(
		"%-18s %-10s %-24s %-24s %-10s\n",
		"ID",
		"TYPE",
		"LOCAL",
		"REMOTE",
		"STATUS",
	)

	fmt.Println(strings.Repeat("-", 92))

	for _, t := range items {
		local := "-"
		remote := "-"

		if t.LocalAddress != "" && t.LocalPort > 0 {
			local = fmt.Sprintf(
				"%s:%d",
				t.LocalAddress,
				t.LocalPort,
			)
		}

		if t.RemoteHost != "" && t.RemotePort > 0 {
			remote = fmt.Sprintf(
				"%s:%d",
				t.RemoteHost,
				t.RemotePort,
			)
		}

		fmt.Printf(
			"%-18s %-10s %-24s %-24s %-10s\n",
			t.ID,
			strings.ToUpper(t.Type),
			local,
			remote,
			t.Status,
		)
	}
}

func status(id string) {
	s, err := core.Status(id)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Printf(
		"Tunnel %s status: %s\n",
		id,
		s,
	)
}

func chooseID(action string, fn func(string)) {
	fmt.Print("Tunnel ID: ")

	in := bufio.NewReader(os.Stdin)

	s, _ := in.ReadString('\n')
	id := strings.TrimSpace(s)

	if id == "" {
		return
	}

	fmt.Println(action, id)
	fn(id)
}
