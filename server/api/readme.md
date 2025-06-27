# Project Corridor Backend (Python/FastAPI)

Converted from Go WebSocket server to Python REST API for MMO game backend.

## Features

- **Authentication**: JWT-based login system (replaces Go's credential handling)
- **Player Data**: Persistent player data management
- **Instance Management**: Game instance creation and lifecycle management
- **REST API**: HTTP endpoints instead of WebSocket messages

## Quick Start

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

3. **Run the Server**
   ```bash
   python -m app.main
   # or
   uvicorn app.main:app --reload
   ```

4. **Access API Documentation**
   - Swagger UI: http://localhost:8080/docs
   - ReDoc: http://localhost:8080/redoc

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - Login with credentials
- `GET /api/v1/auth/me` - Get current user info
- `POST /api/v1/auth/logout` - Logout
- `POST /api/v1/auth/refresh` - Refresh token

### Player Management
- `GET /api/v1/player/data` - Get player data
- `POST /api/v1/player/data` - Update player data
- `POST /api/v1/player/instance` - Request game instance
- `GET /api/v1/player/instances` - List instances

## Migration from Go

### Original Go Features → FastAPI Equivalent

| Go Feature | FastAPI Equivalent |
|------------|-------------------|
| WebSocket connections | HTTP REST endpoints |
| CredentialMessage protobuf | `POST /auth/login` with JSON |
| Client state management | JWT tokens |
| IdMessage for client ID | JWT payload with player_id |
| Hub.RegisterChan | Login endpoint creates session |
| Broadcast messages | Instance management API |

### Usage from Godot

```gdscript
# Login
var http_request = HTTPRequest.new()
var url = "http://localhost:8080/api/v1/auth/login"
var headers = ["Content-Type: application/json"]
var body = JSON.stringify({"user": "admin", "secret": "nimda"})

http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# Get player data (with auth token)
var auth_headers = [
    "Content-Type: application/json",
    "Authorization: Bearer " + access_token
]
http_request.request("http://localhost:8080/api/v1/player/data", auth_headers)
```

## Default Credentials

- Username: `admin`
- Password: `nimda`

(Same as the original Go implementation)

## Development

The server runs on `localhost:8080` by default. Enable debug mode in `.env` for auto-reload during development.

## Architecture Changes

- **Stateless**: No persistent connections, each request is independent
- **Simplified**: Entity management moved to Godot instances
- **Scalable**: Easy to load balance and deploy multiple instances
- **Standard**: Uses HTTP/REST instead of custom WebSocket protocol
