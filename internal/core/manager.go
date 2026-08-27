package core

import (
	"fmt"
	"os"
	"strings"

	"github.com/ReyhanTeam/reyhanTunell/internal/config"
	"github.com/ReyhanTeam/reyhanTunell/internal/system"
)

func service(id string) string {
	return system.ServiceName(id)
}

func Start(id string) {
	if err := system.Run("systemctl", "start", service(id)); err != nil {
		fmt.Println("Error:", err)
	}
}

func Stop(id string) {
	if err := system.Run("systemctl", "stop", service(id)); err != nil {
		fmt.Println("Error:", err)
	}
}

func Restart(id string) {
	if err := system.Restart(service(id)); err != nil {
		fmt.Println("Error:", err)
	}
}

func Logs(id string) {
	if err := system.Logs(service(id)); err != nil {
		fmt.Println("Error:", err)
	}
}

func Status(id string) (string, error) {
	out, err := system.Output(
		"systemctl",
		"is-active",
		service(id),
	)

	if err != nil && strings.TrimSpace(string(out)) != "inactive" {
		return strings.TrimSpace(string(out)), err
	}

	return strings.TrimSpace(string(out)), nil
}

func List() ([]Tunnel, error) {
	ids, err := config.ListIDs()
	if err != nil {
		return nil, err
	}

	var items []Tunnel

	for _, id := range ids {
		var t Tunnel

		if err := config.Load(id, &t); err != nil {
			continue
		}

		status, _ := Status(t.ID)
		t.Status = status

		items = append(items, t)
	}

	return items, nil
}

func Save(t Tunnel) error {
	return config.Save(t.ID, t)
}

func Load(id string) (Tunnel, error) {
	var t Tunnel

	err := config.Load(id, &t)

	return t, err
}

func Remove(id string) {
	_ = system.StopDisable(service(id))
	_ = os.Remove(config.ServicePath(id))
	_ = config.Remove(id)
	_ = system.DaemonReload()

	fmt.Println("Removed:", id)
}
