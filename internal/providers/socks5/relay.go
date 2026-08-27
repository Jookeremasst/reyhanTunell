package socks5

import (
	"fmt"
	"log"
	"net"

	gosocks5 "github.com/armon/go-socks5"
	xcontext "golang.org/x/net/context"

	"github.com/ReyhanTeam/reyhanTunell/internal/core"
)

func RunRelay(t core.Tunnel) error {
	if t.LocalPort < 1 || t.LocalPort > 65535 {
		return fmt.Errorf("invalid local SOCKS5 port")
	}

	if t.RemoteHost == "" {
		return fmt.Errorf("remote SOCKS5 host is empty")
	}

	if t.RemotePort < 1 || t.RemotePort > 65535 {
		return fmt.Errorf("invalid remote SOCKS5 port")
	}

	localAddress := t.LocalAddress

	if localAddress == "" {
		localAddress = "127.0.0.1"
	}

	listenAddress := fmt.Sprintf(
		"%s:%d",
		localAddress,
		t.LocalPort,
	)

	remoteAddress := fmt.Sprintf(
		"%s:%d",
		t.RemoteHost,
		t.RemotePort,
	)

	conf := &gosocks5.Config{
		Dial: func(
			ctx xcontext.Context,
			network string,
			address string,
		) (net.Conn, error) {
			return net.Dial(network, remoteAddress)
		},
	}

	server, err := gosocks5.New(conf)
	if err != nil {
		return fmt.Errorf(
			"create SOCKS5 server: %w",
			err,
		)
	}

	log.Printf(
		"[SOCKS5] Tunnel %s",
		t.ID,
	)

	log.Printf(
		"[SOCKS5] Listening: %s",
		listenAddress,
	)

	log.Printf(
		"[SOCKS5] Remote SOCKS5: %s",
		remoteAddress,
	)

	return server.ListenAndServe(
		"tcp",
		listenAddress,
	)
}
