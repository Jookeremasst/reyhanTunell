package core

type Tunnel struct {
	ID           string `json:"id"`
	Type         string `json:"type"`
	User         string `json:"user"`
	Host         string `json:"host"`
	SSHPort      int    `json:"ssh_port"`
	LocalAddress string `json:"local_address"`
	LocalPort    int    `json:"local_port"`
	RemoteHost   string `json:"remote_host"`
	RemotePort   int    `json:"remote_port"`
	KeyPath      string `json:"key_path"`
	Status       string `json:"status"`
}
