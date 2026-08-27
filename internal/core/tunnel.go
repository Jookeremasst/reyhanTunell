package core

type Tunnel struct {
	ID   string `json:"id"`
	Type string `json:"type"`

	// SSH
	User    string `json:"user"`
	Host    string `json:"host"`
	SSHPort int    `json:"ssh_port"`
	KeyPath string `json:"key_path"`

	// Common
	LocalAddress string `json:"local_address"`
	LocalPort    int    `json:"local_port"`

	// Remote
	RemoteHost string `json:"remote_host"`
	RemotePort int    `json:"remote_port"`

	// SOCKS5
	SOCKS5User string `json:"socks5_user"`
	SOCKS5Pass string `json:"socks5_pass"`

	Status string `json:"status"`
}
