# reyhanTunell

A modular Linux tunnel manager written in Go.

## Installation

Clone or download the project, then run the installer from the project directory:

```bash
sudo bash ./install.sh
```

The installer builds the current source tree and installs the binary to:

```text
/usr/local/bin/reyhanTunell
```

It also creates the standard system paths:

```text
/etc/reyhanTunell/
/etc/reyhanTunell/tunnels/
/var/lib/reyhanTunell/
/var/log/reyhanTunell/
```

After installation, the source directory is not required to run the program. The command is available through the system `PATH`, so it can be started from any directory:

```bash
cd /
sudo reyhanTunell
```

Existing configuration is preserved when the installer is run again.

## Uninstallation

Remove the installed binary and systemd services while keeping configuration, data, and logs:

```bash
sudo bash ./uninstall.sh
```

To remove the binary, services, configuration, data, and logs:

```bash
sudo bash ./uninstall.sh --purge
```

## CLI

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
- `reyhanTunell version`

## API

`reyhanTunell` includes a versioned local HTTP API for the future Laravel web panel.

Start the API manually:

```bash
sudo reyhanTunell api
```

The default address is:

```text
127.0.0.1:8765
```

The API intentionally accepts loopback addresses only in this first version. It is designed for a Laravel panel running on the same server. A random bearer token is generated on first start and stored at:

```text
/etc/reyhanTunell/api.token
```

API endpoints:

```text
GET    /api/v1/health
GET    /api/v1/tunnels
POST   /api/v1/tunnels
GET    /api/v1/tunnels/{id}
PUT    /api/v1/tunnels/{id}
DELETE /api/v1/tunnels/{id}
POST   /api/v1/tunnels/{id}/start
POST   /api/v1/tunnels/{id}/stop
POST   /api/v1/tunnels/{id}/restart
POST   /api/v1/tunnels/{id}/status
POST   /api/v1/tunnels/{id}/logs
```

All endpoints except health require:

```text
Authorization: Bearer <api-token>
```

The API layer uses the Go core and system management packages. It does not access tunnel JSON files directly from Laravel. This keeps the core independent from the future web panel.

## Providers

Current providers:

- SSH
- SOCKS5

The provider layout is designed so future providers such as WireGuard,
OpenVPN, HTTP, and TLS-based transports can be added without changing
the core tunnel storage and systemd management logic.
