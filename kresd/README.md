# Knot DNS Resolver

[![](https://images.microbadger.com/badges/image/kometchtech/kresd.svg)](https://microbadger.com/images/kometchtech/kresd "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/kometchtech/kresd.svg)](https://microbadger.com/images/kometchtech/kresd "Get your own version badge on microbadger.com")
[![GitHub last commit](https://img.shields.io/github/last-commit/google/skia.svg)](https://github.com/kometchtech/docker-build/commits/master/kresd)
[![Docker Pulls](https://img.shields.io/docker/pulls/kometchtech/kresd.svg)](https://hub.docker.com/r/kometchtech/kresd/)

Knot DNS Resolver <https://www.knot-resolver.cz/>

## description

### issue (May 14, 2018)

Currently, the following error of LuaJIT involvement has occurred, it is not possible to check the operation.　　

Also, when building with alpine, the base image is changed to debian because the problem of mounting LMDB fails or the problem of "root.keys': does not exist, bootstrapping" is not solved.

```bash
PANIC: unprotected error in call to Lua API (bad light userdata pointer)
```
- [https://github.com/kometchtech/docker-build/issues/2]
- [https://github.com/kometchtech/docker-build/issues/7]


#### Relation"?"

- [\[ARM64\] Execution of daemon failing, possible deprecated usage of lua_pushlightuserdata (#216) · Issues · Knot projects / Knot Resolver · GitLab](https://gitlab.labs.nic.cz/knot/knot-resolver/issues/216)
- [ARM64 (AArch64) Lua "bad light userdata pointer" · Issue #7879 · neovim/neovim](https://github.com/neovim/neovim/issues/7879)
- [\[arm64\] /usr/bin/luajit: bad light userdata pointer · Issue #1035 · torch/torch7](https://github.com/torch/torch7/issues/1035)
- [arm64: unprotected error in call to Lua API (bad light userdata pointer) #2802](https://github.com/kubernetes/ingress-nginx/issues/2802)

### Baseimage

- [arm64v8/alpine](https://hub.docker.com/r/arm64v8/alpine/)

### minimum operating

```bash
kresd -n -c /etc/knot-resolver/kresd.conf /run/knot-resolver
```

### Notes on running Docker

When forking more than 2 processes, enable `init`.

```bash
docker run --init ...
```

```bash
version: '2.2'
services:
  web:
    image: alpine:latest
    init: true
```

### config

```lua
-- Listen on localhost (default)
-- net = { '127.0.0.1', '::1' }

-- Drop root privileges
user('knot', 'knot')

-- Auto-maintain root TA
trust_anchors.file = 'root.keys'

-- Load Useful modules
modules = {
        'policy',   -- Block queries to local zones/bad sites
        'hints',    -- Load /etc/hosts and allow custom root hints
        'stats',    -- Track internal statistics
        'predict',  -- Prefetch expiring/frequent records
}

-- Smaller cache size
cache.size = 10 * MB
```

### document page

<https://knot-resolver.readthedocs.io/en/stable/>
