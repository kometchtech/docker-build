# BIND

BIND <https://www.isc.org/downloads/bind/>

## description

### Baseimage

arm64v8/alpine

### minimum operating

```bash
docker run -d --name bind9 -p 53:53/tcp -p 53:53/udp -v ${PWD}/named.conf:/etc/bind/named.conf kometchtech/bind9
```

### config

```conf
options {
        directory "/var/bind";

        allow-recursion {
                127.0.0.1/32;
        };

        //forwarders {
        //      123.123.123.123;
        //      123.123.123.123;
        //};

        //forward only;

        listen-on { 127.0.0.1; };
        listen-on-v6 { none; };

        pid-file "/var/run/named/named.pid";

        allow-transfer { none; };
};

zone "." IN {
        type hint;
        file "named.ca";
};

zone "localhost" IN {
        type master;
        file "pri/localhost.zone";
        allow-update { none; };
        notify no;
};

zone "127.in-addr.arpa" IN {
        type master;
        file "pri/127.zone";
        allow-update { none; };
        notify no;
};
```

### document page

- See the Documentation section

<https://www.isc.org/downloads/>