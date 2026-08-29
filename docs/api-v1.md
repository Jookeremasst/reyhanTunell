# reyhanTunell API v1

The API is a local management API for the reyhanTunell Go core. It is intended to be consumed by the Laravel web panel and other local management clients.

## Base address

```text
http://127.0.0.1:8765
```

The server only accepts loopback bind addresses.

## Authentication

All endpoints except `GET /api/v1/health` require:

```http
Authorization: Bearer <API_TOKEN>
```

The token is stored on the server at:

```text
/etc/reyhanTunell/api.token
```

Do not store the token in Git, Laravel source code, or frontend JavaScript.

## Health

```http
GET /api/v1/health
```

Response:

```json
{"ok":true,"service":"reyhanTunell","api_version":"v1"}
```

## Tunnels

### List

```http
GET /api/v1/tunnels
```

Response:

```json
{"data":[...]}
```

### Get

```http
GET /api/v1/tunnels/{id}
```

### Create

```http
POST /api/v1/tunnels
Content-Type: application/json
```

Example SSH payload:

```json
{
  "id": "ssh-demo",
  "type": "ssh",
  "user": "root",
  "host": "203.0.113.10",
  "ssh_port": 22,
  "key_path": "/root/.ssh/id_ed25519",
  "local_address": "127.0.0.1",
  "local_port": 8443,
  "remote_host": "127.0.0.1",
  "remote_port": 443
}
```

Example SOCKS5 payload:

```json
{
  "id": "socks-demo",
  "type": "socks5",
  "local_address": "127.0.0.1",
  "local_port": 8443,
  "remote_host": "127.0.0.1",
  "remote_port": 8443,
  "socks5_user": "user",
  "socks5_pass": "pass"
}
```

Supported types in API v1 are currently `ssh` and `socks5`.

### Update

```http
PUT /api/v1/tunnels/{id}
Content-Type: application/json
```

The path ID is authoritative. The body ID is replaced with the path ID.

### Delete

```http
DELETE /api/v1/tunnels/{id}
```

This stops and disables the systemd service, removes the service unit and removes the tunnel configuration.

## Service actions

All actions use `POST`.

```text
POST /api/v1/tunnels/{id}/start
POST /api/v1/tunnels/{id}/stop
POST /api/v1/tunnels/{id}/restart
POST /api/v1/tunnels/{id}/status
POST /api/v1/tunnels/{id}/logs
```

Example action response:

```json
{"id":"test","action":"started","ok":true}
```

Status response:

```json
{"id":"test","status":"active"}
```

Logs response:

```json
{"id":"test","logs":"..."}
```

## Errors

Errors use JSON:

```json
{"error":"unauthorized"}
```

Common HTTP status codes:

- `200` success
- `201` tunnel created
- `204` successful delete
- `400` invalid request
- `401` missing or invalid token
- `404` tunnel or action not found
- `405` HTTP method not allowed
- `500` internal or systemd error

## Laravel integration rule

Laravel must call this API from the server side. The API token must stay on the server and must never be sent to browser JavaScript.

Recommended flow:

```text
Browser
   |
   v
Laravel
   |
   | Bearer token
   v
reyhanTunell API
   |
   v
Go Core / systemd / providers
```

This keeps the Go core independent from the Laravel UI and allows the UI to be replaced later without changing tunnel management logic.
