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

or:

```bash
cd /tmp
sudo reyhanTunell list
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

The provider layout is designed so future providers such as WireGuard,
OpenVPN, SOCKS5, and TLS-based transports can be added without changing
the core tunnel storage and systemd management logic.
