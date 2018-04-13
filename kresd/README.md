# Knot DNS Resolver

Knot DNS Resolver <https://www.knot-resolver.cz/>

## description

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
