# ISC Stork Agent

ISC のリリースソースからエージェントをビルドします。ビルドと設定については
[サーバー側の README](../stork-server/README.md) を参照してください。

## Image details

| Item | Value |
|---|---|
| Base images | `golang:latest` and `node:current` (build stages), `debian:stable-slim` (runtime) |
| Exposed ports | `8080`, `9547`, `9119` (agent listener and Kea/BIND 9 Prometheus exporters) |
| Entrypoint | `/usr/bin/stork-agent` |
| Version file | `VERSION` (local-only; ISC release source used by the build) |

## Build

The `stork-agent` Dockerfile and `VERSION` file are only present in local
checkouts and are not tracked in this repository, so no build command is
provided here.
