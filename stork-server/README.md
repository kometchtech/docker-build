# ISC Stork Server

ISC のリリースソースからサーバー、管理ツール、Web UI をビルドします。
エージェントは `stork-agent` ディレクトリのイメージを使用します。

```sh
docker build --build-arg VERSION="$(cat stork-server/VERSION)" \
  -t kometchtech/stork-server:$(cat stork-server/VERSION) stork-server
```

エージェントのビルドは `stork-agent` の README を参照してください。

サーバーには PostgreSQL が必要です。事前にデータベース、ユーザー、pgcrypto 拡張を準備し、
`STORK_DATABASE_HOST`、`STORK_DATABASE_NAME`、`STORK_DATABASE_USER_NAME`、
`STORK_DATABASE_PASSWORD` などを環境変数で指定してください。8080 番ポートで Web UI を公開します。
DB の永続化と認証情報の管理は利用する環境側で設定してください。

エージェントは監視対象のプロセスや設定にアクセスできる必要があります。コンテナを分離すると
自動検出に必要なプロセスやファイルが見えないため、対象環境に合わせて PID 名前空間、
設定ファイル、ソケット、権限を設定し、エージェントの認証情報を永続化してください。
登録・接続方法や設定の詳細は [ISC のインストール手順](https://stork.readthedocs.io/en/v2.6.0/install.html) を参照してください。

## Image details

| Item | Value |
|---|---|
| Base images | `golang:latest` and `node:current` (build stages), `debian:stable-slim` (runtime) |
| `STORK_REST_HOST` | `0.0.0.0` (set in the Dockerfile so the published port is reachable) |
| Exposed port | `8080` |
| Entrypoint | `/usr/bin/stork-server` |
| Version file | `VERSION` (local-only; ISC release source used by the build) |
