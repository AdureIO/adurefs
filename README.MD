# adurefs — Shared Filesystem Volume Driver

A lightweight Docker volume plugin by [Adure](https://adure.io) that enables
named volumes on any shared filesystem (GlusterFS, NFS, CephFS, etc.) mounted
at a common path across all nodes in a Docker Swarm cluster.

## Why adurefs?

Standard Docker named volumes are node-local. In a Swarm cluster, when a
container reschedules to a different node, it loses access to its data.

adurefs solves this by creating volumes as subdirectories of a shared
filesystem mount — making named volumes automatically available on every node
without replication overhead or complex plugin dependencies.

## Installation

```bash
docker plugin install adure/adurefs \
  ADUREFS_BASE_PATH=/mnt/gluster/swarm/volumes \
  --grant-all-permissions
```

## Configuration

| Variable            | Default               | Description                                         |
| ------------------- | --------------------- | --------------------------------------------------- |
| `ADUREFS_BASE_PATH` | `/mnt/shared/volumes` | Base directory for volumes on the shared filesystem |
| `ADUREFS_LOG_LEVEL` | `INFO`                | Log level: DEBUG, INFO, WARNING, ERROR              |

## Usage

### In compose/stack files

```yaml
services:
    db:
        image: postgres:15
        volumes:
            - db_data:/var/lib/postgresql/data

volumes:
    db_data:
        driver: adurefs
```

### Set as default driver (no driver needed in compose files)

Add to `/etc/docker/daemon.json` on all nodes:

```json
{
	"volume-driver": "adurefs"
}
```

Then restart Docker and use plain named volumes:

```yaml
volumes:
    db_data: # automatically uses adurefs
```

### Manual volume management

```bash
# Create
docker volume create --driver adurefs my_data

# List
docker volume ls --filter driver=adurefs

# Inspect
docker volume inspect my_data

# Remove (data preserved on shared filesystem by default)
docker volume rm my_data
```

## Requirements

- Shared filesystem mounted at the same path on all Swarm nodes
- Works with: GlusterFS, NFS, CephFS, or any POSIX-compatible shared mount

## Building from source

```bash
git clone https://github.com/adureio/adurefs
cd adurefs

# Build rootfs
docker build -t adurefs-rootfs .
id=$(docker create adurefs-rootfs true)
mkdir -p rootfs
docker export "$id" | tar -x -C rootfs
docker rm -vf "$id"
docker rmi adurefs-rootfs

# Create and push plugin
docker plugin create adureio/adurefs .
docker plugin push adureio/adurefs
```

## Notes

- Volume **Remove** preserves data on the shared filesystem by default
  (safe for shared storage — prevents accidental data loss)
- Volume **Scope** is `global` — Docker Swarm knows the volume is
  available on all nodes
- No external Python dependencies — uses stdlib only

## License

MIT — © Adure (adure.io)
