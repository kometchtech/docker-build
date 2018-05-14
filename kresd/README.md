# Knot DNS Resolver

Knot DNS Resolver <https://www.knot-resolver.cz/>

## description

### issue

Currently, the following error of LuaJIT involvement has occurred, it is not possible to check the operation.

```bash
PANIC: unprotected error in call to Lua API (bad light userdata pointer)
```

#### Relation ?

[\[ARM64\] Execution of daemon failing, possible deprecated usage of lua_pushlightuserdata (#216) · Issues · Knot projects / Knot Resolver · GitLab](https://gitlab.labs.nic.cz/knot/knot-resolver/issues/216)

[ARM64 (AArch64) Lua "bad light userdata pointer" · Issue #7879 · neovim/neovim](https://github.com/neovim/neovim/issues/7879)

[\[arm64\] /usr/bin/luajit: bad light userdata pointer · Issue #1035 · torch/torch7](https://github.com/torch/torch7/issues/1035)

### Baseimage

arm64v8/alpine

### minimum operating

### config

```lua
-- Listen on localhost (default)
-- net = { '127.0.0.1', '::1' }

-- Drop root privileges
-- user('knot-resolver', 'knot-resolver')

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
