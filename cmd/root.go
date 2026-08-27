package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/core"
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
	case "add":
		runAdd()
	case "list":
		list()
	case "status":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell status <id>"); return }
		status(os.Args[2])
	case "start":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell start <id>"); return }
		core.Start(os.Args[2])
	case "stop":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell stop <id>"); return }
		core.Stop(os.Args[2])
	case "restart":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell restart <id>"); return }
		core.Restart(os.Args[2])
	case "remove":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell remove <id>"); return }
		core.Remove(os.Args[2])
	case "logs":
		if len(os.Args) < 3 { fmt.Println("Usage: reyhanTunell logs <id>"); return }
		core.Logs(os.Args[2])
	case "version":
		fmt.Println("reyhanTunell v0.1.0")
	default:
		fmt.Println("Unknown command:", os.Args[1])
		fmt.Println("Use: reyhanTunell menu")
	}
}

func menu() {
	for {
		fmt.Println()
		fmt.Println("==============================================")
		fmt.Println("          reyhanTunell - SSH Manager")
		fmt.Println("==============================================")
		fmt.Println(" 1. Add SSH Tunnel")
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
		in := bufio.NewReader(os.Stdin)
		s, _ := in.ReadString('\n')
		s = strings.TrimSpace(s)

		switch s {
		case "1": runAdd()
		case "2": list()
		case "3": chooseID("Restart", core.Restart)
		case "4": chooseID("Start", core.Start)
		case "5": chooseID("Stop", core.Stop)
		case "6": chooseID("Status", status)
		case "7": chooseID("Logs", core.Logs)
		case "8": chooseID("Remove", core.Remove)
		case "0": return
		default: fmt.Println("Invalid selection.")
		}
	}
}

func runAdd() {
	if err := ssh.AddInteractive(); err != nil {
		fmt.Println("Error:", err)
	}
}

func list() {
	items, err := core.List()
	if err != nil { fmt.Println("Error:", err); return }
	if len(items) == 0 {
		fmt.Println("No tunnels configured.")
		return
	}
	fmt.Printf("%-18s %-8s %-20s %-24s %-10s\n", "ID", "TYPE", "LOCAL", "REMOTE", "STATUS")
	fmt.Println(strings.Repeat("-", 88))
	for _, t := range items {
		fmt.Printf("%s | %s | %s:%d -> %s:%d | %s\n",
	t.ID,
	t.Type,
	t.LocalAddress,
	t.LocalPort,
	t.RemoteHost,
	t.RemotePort,
	t.Status,
)
	}
}

func status(id string) {
	s, err := core.Status(id)
	if err != nil { fmt.Println("Error:", err); return }
	fmt.Println(s)
}

func chooseID(action string, fn func(string)) {
	fmt.Print("Tunnel ID: ")
	in := bufio.NewReader(os.Stdin)
	s, _ := in.ReadString('\n')
	id := strings.TrimSpace(s)
	if id == "" { return }
	fmt.Println(action, id)
	fn(id)
}
