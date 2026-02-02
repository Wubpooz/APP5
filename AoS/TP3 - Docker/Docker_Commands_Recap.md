# Docker Commands Recap

This document summarizes all Docker commands covered in the tutorials, organized by command type.

## Container Management Commands

### `docker container run`
Start and run a new container from an image.

**Options:**
- `-d` - Run container in detached mode (background)
- `-it` - Run in interactive mode with TTY (terminal)
- `-i` - Keep STDIN open (interactive)
- `-t` - Allocate a pseudo-TTY
- `--name <name>` - Assign a custom name to the container
- `-p <host-port>:<container-port>` - Map host port to container port
- `-P` - Map all exposed ports to random host ports
- `-v <volume>:<container-path>` - Mount a volume
- `-e <KEY>=<value>` - Set environment variables
- `--network <network>` - Connect container to a specific network

**Examples:**
```bash
docker container run centos:7 echo "hello world"
docker container run -d centos:7 ping 127.0.0.1
docker container run -it centos:7 bash
docker container run -d -p 5000:80 nginx
docker container run --name u1 -dt centos:7
```

### `docker container ls`
List containers.

**Options:**
- `-a` - Show all containers (including stopped ones)
- `-q` - Only display container IDs
- `-l` - Show the last created container
- `--no-trunc` - Don't truncate output (show full IDs)
- `--filter <key>=<value>` - Filter output based on conditions

**Examples:**
```bash
docker container ls
docker container ls -a
docker container ls -aq
docker container ls --filter "exited=0"
docker container ls --filter "status=exited"
```

### `docker container rm`
Remove one or more containers.

**Options:**
- `-f` - Force remove running containers

**Examples:**
```bash
docker container rm <container-id>
docker container rm -f <container-id>
docker container rm -f $(docker container ls -aq)
```

### `docker container start`
Start one or more stopped containers.

**Options:**
- `-a` - Attach STDOUT/STDERR and forward signals

**Examples:**
```bash
docker container start <container-id>
docker container start -a <container-id>
```

### `docker container stop`
Stop one or more running containers gracefully (SIGTERM, then SIGKILL after 10s).

**Examples:**
```bash
docker container stop <container-id>
```

### `docker container kill`
Kill one or more running containers immediately (SIGKILL).

**Examples:**
```bash
docker container kill <container-id>
```

### `docker container exec`
Execute a command in a running container.

**Options:**
- `-it` - Interactive mode with TTY
- `-i` - Keep STDIN open
- `-t` - Allocate a pseudo-TTY

**Examples:**
```bash
docker container exec <container-id> ps -ef
docker container exec -it <container-id> bash
docker container exec -it some-postgres psql -U postgres
```

### `docker container logs`
Fetch the logs of a container (STDOUT/STDERR of PID 1).

**Options:**
- `-f` - Follow log output in real time
- `--tail <n>` - Show only the last n lines

**Examples:**
```bash
docker container logs <container-id>
docker container logs --tail 5 <container-id>
docker container logs -f <container-id>
```

### `docker container attach`
Attach local standard input, output, and error streams to a running container's PID 1.

**Examples:**
```bash
docker container attach <container-id>
```

**Note:** `CTRL+P` then `CTRL+Q` to detach without stopping; `CTRL+C` kills PID 1.

### `docker container inspect`
Display detailed information about a container (JSON format).

**Options:**
- `--format <template>` - Format output using Go template

**Examples:**
```bash
docker container inspect <container-id>
docker container inspect <container-id> | grep IPAddress
docker container inspect --format='{{.Config.Cmd}}' <container-id>
docker container inspect --format='{{json .Config}}' <container-id>
```

### `docker container diff`
Show changes to files/directories in a container's filesystem.

**Output codes:**
- `A` - Added
- `C` - Changed
- `D` - Deleted

**Examples:**
```bash
docker container diff <container-id>
```

### `docker container commit`
Create a new image from a container's changes.

**Examples:**
```bash
docker container commit <container-id> myapp:1.0
```

### `docker container top`
Display the running processes of a container from the host perspective.

**Examples:**
```bash
docker container top <container-id>
```

### `docker container port`
List port mappings for a container.

**Examples:**
```bash
docker container port <container-id>
```

## Image Management Commands

### `docker image build`
Build an image from a Dockerfile.

**Options:**
- `-t <name:tag>` - Name and optionally tag the image
- `-f <dockerfile>` - Specify Dockerfile location (or use `-` for STDIN)
- `--target <stage>` - Build a specific stage in multi-stage build

**Examples:**
```bash
docker image build -t myimage .
docker image build -t my-app-small .
docker image build -t my-build-stage --target build .
cat Dockerfile | docker image build -t myimage -f - .
```

### `docker image ls`
List images.

**Examples:**
```bash
docker image ls
docker image ls | grep my-app-large
```

### `docker image history`
Show the history/layers of an image.

**Examples:**
```bash
docker image history myimage:latest
```

### `docker image inspect`
Display detailed information about an image (JSON format).

**Examples:**
```bash
docker image inspect postgres:9
```

### `docker pull`
Download an image from a registry.

**Examples:**
```bash
docker pull postgres:9
```

## Network Management Commands

### `docker network ls`
List networks.

**Examples:**
```bash
docker network ls
```

### `docker network create`
Create a new network.

**Options:**
- `--driver <driver>` - Specify network driver (e.g., bridge)

**Examples:**
```bash
docker network create --driver bridge my_bridge
```

### `docker network inspect`
Display detailed information about a network.

**Examples:**
```bash
docker network inspect bridge
docker network inspect my_bridge
```

## Volume Management Commands

### Named Volumes
Volumes are created automatically when specified with `-v` flag in `docker container run`, or can be created explicitly with `docker volume create`.

**Usage in container run:**
```bash
docker container run -v db_backing:/var/lib/postgresql/data -d postgres:9
```

## Docker Compose Commands

### `docker-compose up`
Create and start containers defined in docker-compose.yml.

**Options:**
- `-d` - Run in detached mode (background)

**Examples:**
```bash
docker-compose up
docker-compose up -d
```

### `docker-compose ps`
List containers managed by Compose.

**Examples:**
```bash
docker-compose ps
```

### `docker-compose logs`
View logs from services.

**Options:**
- `--tail=<n>` - Show only the last n lines
- `--follow` - Follow log output in real time

**Examples:**
```bash
docker-compose logs
docker-compose logs --tail=10 --follow
```

### `docker-compose scale`
Scale a service to a specific number of containers.

**Examples:**
```bash
docker-compose scale worker=2
docker-compose scale worker=10
```

### `docker-compose down`
Stop and remove containers, networks created by up.

**Examples:**
```bash
docker-compose down
```

## Dockerfile Instructions

### `FROM`
Specify the base image for the build.

**Example:**
```dockerfile
FROM centos:7
FROM alpine:3.5
FROM alpine:3.5 AS build
```

### `RUN`
Execute commands in the image during build.

**Example:**
```dockerfile
RUN yum update -y
RUN yum install -y wget vim
RUN apk update && apk add --update alpine-sdk
```

### `CMD`
Provide default command/arguments for container (can be overridden at runtime).

**Example:**
```dockerfile
CMD ["ping", "127.0.0.1", "-c", "5"]
CMD ["127.0.0.1"]
CMD /app/hello
```

### `ENTRYPOINT`
Configure container to run as an executable (arguments appended at runtime).

**Example:**
```dockerfile
ENTRYPOINT ["ping"]
ENTRYPOINT ["ping", "-c", "3"]
```

### `COPY`
Copy files/directories from build context to image.

**Example:**
```dockerfile
COPY hello.c /app
COPY --from=build /app/bin/hello /app/hello
```

### `WORKDIR`
Set working directory for subsequent instructions.

**Example:**
```dockerfile
WORKDIR /app
```

### `EXPOSE`
Document which ports should be published (used with `-P` flag).

**Example:**
```dockerfile
EXPOSE 80
```

## Common Command Patterns

### Cleanup Commands
```bash
# Remove all containers
docker container rm -f $(docker container ls -aq)

# Remove specific exited containers
docker container ls --filter "status=exited" -q
docker container rm <container-id>
```

### Inspection Patterns
```bash
# Get container IP
docker container inspect --format='{{.NetworkSettings.IPAddress}}' <container-id>

# Get config as JSON
docker container inspect --format='{{json .Config}}' <container-id> | jq

# Check network connections
ip addr
brctl show docker0
```

### Multi-stage Build Pattern
```dockerfile
# Build stage
FROM alpine:3.5 AS build
# ... build steps ...

# Production stage
FROM alpine:3.5
COPY --from=build /app/bin/hello /app/hello
CMD /app/hello
```

## Key Concepts

- **Container Lifecycle**: run → start/stop → rm
- **Detached vs Interactive**: `-d` for background, `-it` for interactive
- **Image Layers**: Each Dockerfile instruction creates a layer; cached layers speed up builds
- **Networking**: Default bridge network vs custom networks (custom provides DNS resolution)
- **Volumes**: Persist data beyond container lifecycle
- **Port Mapping**: `-p host:container` or `-P` with EXPOSE
- **CMD vs ENTRYPOINT**: CMD provides defaults (overridable), ENTRYPOINT makes container executable
