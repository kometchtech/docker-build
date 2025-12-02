#!/usr/bin/env sh

set -e

# デフォルトのコマンドとパラメータ
DEFAULT_CMD="dnsdist --supervised --disable-syslog --log-timestamps -u _dnsdist -g _dnsdist --config /etc/dnsdist/dnsdist.yaml"

# 引数が渡されていれば使用し、なければデフォルトを使用
if [ $# -eq 0 ]; then
    # 引数がない場合はデフォルトコマンドを使用
    exec $DEFAULT_CMD
else
    # 引数がある場合はそれを使用
    exec "$@"
fi
