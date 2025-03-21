#!/bin/bash
set -eo pipefail

# ディレクトリのパーミッション設定
echo "Setting up permissions for BIND directories..."
chown -R _named:_named /etc/named /var/cache/named /var/run/named /var/cache/named/dynamic

# named.conf が存在しない場合、デフォルトの設定をコピー
if [ ! -f /etc/named/named.conf ]; then
    echo "No configuration found, using default named.conf..."
    cp /etc/named/named.conf.default /etc/named/named.conf
fi

# 環境変数から設定を動的に生成する機能をここに追加できます
# 例: sed -i 's/REPLACE_WITH_FORWARDERS/'"${DNS_FORWARDERS}"'/' /etc/named/named.conf

# 引数がある場合はそれを使用し、ない場合はデフォルトのコマンドを実行
echo "Starting BIND DNS server..."
if [ $# -eq 0 ]; then
    exec /usr/local/sbin/named -c /etc/named/named.conf -g -u _named
else
    exec "$@"
fi
