# Project-Corridor

# Project Structure

This repo contains **3** Godot projects!
- Client Code
- Server Code
- Shared Code

Shared code is exposed to the client and server via links (shown below).

```
/project-corridor
    shared-code/
        utils.gd
    pc-client/
        shared/ -> symlink to ../shared-code
    pc-server/
        shared/ -> symlink to ../shared-code
```
