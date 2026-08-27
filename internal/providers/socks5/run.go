package socks5

import (
	"fmt"

	"github.com/ReyhanTeam/reyhanTunell/internal/core"
)

func Run(id string) error {
	t, err := core.Load(id)
	if err != nil {
		return fmt.Errorf("load tunnel %s: %w", id, err)
	}

	if t.Type != "socks5" {
		return fmt.Errorf("tunnel %s is not SOCKS5", id)
	}

	return RunRelay(t)
}
