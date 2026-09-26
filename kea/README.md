# ISC Kea container

Kea 3.3.1 の DHCPv4 / DHCPv6 サーバーをソースからビルドします。
Kea Control Agent は 3.2 以降に含まれないため、各 DHCP デーモンの直接 HTTP API を使用します。
詳細は [ISC の移行ガイド](https://kb.isc.org/docs/kea-control-agent-migration) を参照してください。

## ビルド

リポジトリのルートで実行します。

```sh
docker build --build-arg VERSION="$(cat kea/VERSION)" -t kea:direct-api-test kea
```

最終イメージのビルド時に `kea-dhcp4 -v` と `kea-dhcp6 -v` を実行し、
バイナリと実行時ライブラリが利用できることを確認します。

## DHCP パケットを配布せずに起動を確認する

`examples/direct-api` は API の起動確認用です。DHCP 待受インターフェースとサブネットは空で、
リースの永続化も無効です。運用設定をこの例で上書きしないでください。

Linux ホストで次のコマンドを実行します。8004 / 8006 番ポートが空いていることが前提です。

```sh
docker run -d --name kea-direct-api --network host \
  --mount "type=bind,src=$(pwd)/kea/examples/direct-api,dst=/etc/kea,readonly" \
  kea:direct-api-test
docker logs kea-direct-api
```

設定例では DHCPv4 と DHCPv6 を `keactrl` で起動し、DDNS / NETCONF は起動しません。
設定ファイルは `/etc/kea`、実行ファイルは `/usr/local/sbin` を明示しています。
この指定により、生成された `keactrl.conf` が `/usr/local/etc/kea` を参照する場合の
設定ファイルの読み込み失敗も避けられます。

| サービス | 同じホストからの接続先 |
| --- | --- |
| DHCPv4 | `http://127.0.0.1:8004/` |
| DHCPv6 | `http://127.0.0.1:8006/` |

API はホストのループバックだけで待ち受けます。`--network host` を使うため `-p` は不要です。
Kea 3.3.1 は認証も TLS もない HTTP 設定を拒否するため、この例には検証専用の Basic 認証
（ユーザー `kea-api-test`、パスワード `local-test-only`）を設定しています。
認証情報は `api-credentials` の `ユーザー:パスワード` を `password-file` で読み込みます。
3.3.1 は JSON 内への `user` / `password` の直接記述も拒否します。
この公開された認証情報は運用に使用せず、既存の認証設定を保持するか専用の認証情報に置き換えてください。

```sh
for port in 8004 8006; do
  for command in version-get status-get; do
    curl --noproxy '*' --fail-with-body --silent --show-error \
      --user 'kea-api-test:local-test-only' \
      -H 'Content-Type: application/json' \
      -d "{\"command\":\"${command}\"}" "http://127.0.0.1:${port}/"
    printf '\n'
  done
done
```

各応答は JSON 配列で返ります。HTTP ステータスに加え、各要素の `result` が `0` であることを
確認してください。直接 API では接続先ポートでサービスを選ぶため、リクエストに `service` は指定しません。

```sh
docker restart kea-direct-api
# 再度、上記の API 呼び出しで両方の応答を確認します。
docker rm -f kea-direct-api
```

## 既存の運用設定を移行する

1. 既存の `kea-dhcp4.conf` の `Dhcp4` と `kea-dhcp6.conf` の `Dhcp6` に、
   対応する設定例の HTTP リスナーを `control-sockets` 配列の要素として追加します。
   既存の `control-socket`（単数形）がある場合は、そのオブジェクトを同じ配列に移します。
   既存の UNIX ソケット、認証 / TLS、サブネット、予約、DB 設定を保持してください。
   Basic 認証の `user` / `password` が JSON に直接書かれている場合は、認証情報を
   `ユーザー:パスワード` 形式のファイルへ移し、`password-file` で参照します。
   このファイルをコンテナから読み取れる場所にマウントし、ホスト側の読み取り権限を制限します。
2. `keactrl.conf` の設定ファイルパスを `/etc/kea` に合わせます。
   Control Agent 用の設定項目を削除し、必要な DHCP サービスを有効にします。
3. 各設定を `kea-dhcp4 -t /etc/kea/kea-dhcp4.conf` と
   `kea-dhcp6 -t /etc/kea/kea-dhcp6.conf` で検証します。
   コンテナでは `--entrypoint kea-dhcp4` または `--entrypoint kea-dhcp6` を指定し、
   設定ディレクトリを同じようにマウントして実行できます。
4. 運用設定を `/etc/kea` にマウントして起動し、管理クライアントの接続先を
   DHCPv4 は 8004、DHCPv6 は 8006 に変更します。従来の Agent の 1 回の呼び出しで
   両サービスを操作していた場合は、各サービスへの呼び出しに分けます。

この例は同じホストからの接続専用です。運用環境の認証 / TLS を各リスナーへ引き継ぐ際は、
[DHCPv4 の HTTP API](https://kea.readthedocs.io/en/kea-3.3.1/arm/dhcp4-srv.html#http-https-control-socket) と
[DHCPv6 の HTTP API](https://kea.readthedocs.io/en/kea-3.3.1/arm/dhcp6-srv.html#http-https-control-socket) を参照してください。

## 自動検証

ビルド後に、Docker と Python 3 が使える Linux ホストで実行します。

```sh
python3 kea/tests/smoke.py kea:direct-api-test
```

バージョン、共有ライブラリ、両設定の構文、通常の entrypoint での起動、両 API の
`version-get` / `status-get`、認証なしのリクエストの拒否、コンテナ再起動後の API 応答を検証します。
テスト用コンテナは終了時に削除されます。
