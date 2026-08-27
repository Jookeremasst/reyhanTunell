# reyhanTunell

A modular Linux tunnel manager written in Go.

Current provider:
- SSH local port forwarding

CLI:
- `reyhanTunell` -> interactive menu
- `reyhanTunell menu`
- `reyhanTunell add`
- `reyhanTunell list`
- `reyhanTunell status <id>`
- `reyhanTunell start <id>`
- `reyhanTunell stop <id>`
- `reyhanTunell restart <id>`
- `reyhanTunell logs <id>`
- `reyhanTunell remove <id>`

The provider layout is designed so future providers such as WireGuard,
OpenVPN, SOCKS5, and TLS-based transports can be added without changing
the core tunnel storage and systemd management logic.
