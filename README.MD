# adurefs — Shared Filesystem Volume Driver

A lightweight Docker volume plugin by [Adure](https://adure.io) that enables
named volumes on any shared filesystem mounted at a common path across all
nodes in a Docker Swarm cluster.

## Why adurefs?

Standard Docker named volumes are node-local. In a Swarm cluster, when a
container reschedules to a different node, it loses access to its data.

adurefs solves this by creating volumes as subdirectories of a shared
filesystem mount — making named volumes automatically available on every node
without replication overhead or complex plugin dependencies.

The plugin returns the host-side shared filesystem path directly as the Mountpoint.
Docker performs a plain bind mount — no PropagatedMount, no extra FUSE layer,
no orphaned handles on unclean shutdown.

## Installation

```bash
docker plugin install adureio/adurefs \
  volumes.source=/mnt/swarm/volumes \
  --grant-all-permissions
```

## Upgrade

```bash
docker plugin disable --force adureio/adurefs:latest
docker plugin upgrade adureio/adurefs:latest
docker plugin set adureio/adurefs:latest volumes.source=/mnt/swarm/volumes
docker plugin enable adureio/adurefs:latest
```

## Configuration

| Variable            | Default | Settable | Description                                                         |
| ------------------- | ------- | -------- | ------------------------------------------------------------------- |
| `volumes.source`    | —       | yes      | Host path of the shared filesystem mount (required)                 |
| `ADUREFS_KEEP_DATA` | `true`  | yes      | When true, Remove only deletes the volume record, data is preserved |
| `ADUREFS_LOG_LEVEL` | `INFO`  | yes      | Log level: DEBUG, INFO, WARNING, ERROR                              |

> `ADUREFS_BASE_PATH` is the plugin-internal mount path and must not be changed.

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
        driver: adureio/adurefs:latest
```

### Manual volume management

```bash
# Create
docker volume create --driver adureio/adurefs:latest my_data

# List
docker volume ls --filter driver=adureio/adurefs:latest

# Inspect
docker volume inspect my_data

# Remove (data preserved on shared filesystem by default)
docker volume rm my_data
```

## Requirements

- Shared filesystem mounted at the **same path on all Swarm nodes** before Docker starts
- Any POSIX-compatible shared mount (NFS, CephFS, etc.)
- Recommended: mount via a systemd `.mount` unit with `After=network-online.target` and `Before=docker.service`

## Building from source

```bash
sh build.sh
```

## Notes

- Volume **Remove** preserves data on the shared filesystem by default
  (`ADUREFS_KEEP_DATA=true`) — prevents accidental data loss on shared storage
- Volume **Scope** is `global` — Docker Swarm knows the volume is available on all nodes
- No PropagatedMount — the plugin returns the host shared filesystem path directly,
  avoiding stale FUSE handles on unclean shutdown
- No external Python dependencies — uses stdlib only
- For containers with frequent writes to shared storage (e.g. MongoDB), increase
  `stop_grace_period` so the process flushes cleanly before Docker kills it

## License

MIT — © Adure (adure.io)
