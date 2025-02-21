# Intermediate container for build
FROM debian:12 AS build

ARG VERSION
ARG BUILD_PKGS="apt-transport-https ca-certificates wget pipx devscripts mkdocs "

RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get -qqq -y install ${BUILD_PKGS} ${PY_PKGS}
RUN pipx install apkg

RUN wget -O /usr/share/keyrings/cznic-labs-pkg.gpg https://pkg.labs.nic.cz/gpg && \
	echo "deb [signed-by=/usr/share/keyrings/cznic-labs-pkg.gpg] https://pkg.labs.nic.cz/knot-resolver bookworm main" \
		> /etc/apt/sources.list.d/cznic-labs-knot-resolver.list && \
	apt-get update -qq

# Knot Resolver build
RUN git clone -b v${VERSION} --depth=1 --recursive https://gitlab.nic.cz/knot/knot-resolver.git /source

RUN cd /source && \
	export PATH="$PATH:/root/.local/bin" && \
	git submodule update --init --recursive && \
	git config --global user.name "Docker Build" && \
	git config --global user.email docker-build@knot-resolver && \
	\
        # Replace 'knot-resolver' user and group with 'root'
	# in meson_options.tx and python/knot_resolver/constants.py.
	# This is needed for the file/directory permissions validation
	# and then for the proper functioning of the resolver.
	sed s/knot-resolver/root/g -i meson_options.txt && \
	sed 's/unit_tests=enabled/unit_tests=disabled/g' -i distro/pkg/deb/rules && \
	sed -e '/unit_tests=disabled/a -Ddoc=disabled \' -i distro/pkg/deb/rules && \
	sed 's/USER.*/USER = "root"/g' -i python/knot_resolver/constants.py && \
	sed 's/GROUP.*/GROUP = "root"/g' -i python/knot_resolver/constants.py && \
	git commit -a -m TMP && \
	\
	/root/.local/bin/apkg build-dep -y && \
	/root/.local/bin/apkg build 


# Real container
FROM debian:12-slim AS runtime

RUN apt-get update -qq && \
	apt-get -qqq -y install apt-transport-https ca-certificates

COPY --from=build \
	/usr/share/keyrings/cznic-labs-pkg.gpg \
	/usr/share/keyrings/cznic-labs-pkg.gpg
COPY --from=build \
	/etc/apt/sources.list.d/cznic-labs-knot-resolver.list \
	/etc/apt/sources.list.d/cznic-labs-knot-resolver.list

RUN apt-get update -qq && \
	apt-get upgrade -qq

COPY --from=build /source/pkg/pkgs/debian-12 /pkg

# install resolver, minimize image and prepare config directory
RUN apt-get install -y /pkg/*/*.deb && \
	rm -r /pkg && \
	apt-get remove -y -qq curl gnupg2 && \
	apt-get autoremove -y && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* 

COPY --from=build /source/etc/config/config.example.docker.yaml /etc/knot-resolver/config.yaml

LABEL cz.knot-resolver.vendor="cz.nic"
LABEL maintainer="kometch@gmail.com"

# Export plain DNS, DoT, DoH and management interface
EXPOSE 53/UDP 53/TCP 443/TCP 853/TCP 5000/TCP

# Prepare shared config
VOLUME /etc/knot-resolver
# Prepare shared cache
VOLUME /var/cache/knot-resolver

ENTRYPOINT ["/usr/bin/knot-resolver"]
CMD ["-c", "/etc/knot-resolver/config.yaml"]

