# Multi-stage build for Knot Resolver
# Stage 1: Build environment
FROM debian:12 AS build

# Build arguments
ARG VERSION=6.0.11
ARG BUILD_PKGS="apt-transport-https ca-certificates wget pipx devscripts mkdocs git"

# Install build dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update -qq && \
    apt-get -qqq -y install ${BUILD_PKGS} && \
    pipx install apkg && \
    # Add Knot Resolver repository
    wget -O /usr/share/keyrings/cznic-labs-pkg.gpg https://pkg.labs.nic.cz/gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cznic-labs-pkg.gpg] https://pkg.labs.nic.cz/knot-resolver bookworm main" \
        > /etc/apt/sources.list.d/cznic-labs-knot-resolver.list && \
    apt-get update -qq

# Clone and build Knot Resolver
RUN git clone -b v${VERSION} --depth=1 --recursive https://gitlab.nic.cz/knot/knot-resolver.git /source && \
    cd /source && \
    export PATH="$PATH:/root/.local/bin" && \
    git submodule update --init --recursive && \
    git config --global user.name "Docker Build" && \
    git config --global user.email docker-build@knot-resolver && \
    # Replace 'knot-resolver' user and group with 'root'
    # This is needed for file/directory permissions validation
    # and proper functioning of the resolver
    sed s/knot-resolver/root/g -i meson_options.txt && \
    sed 's/unit_tests=enabled/unit_tests=disabled/g' -i distro/pkg/deb/rules && \
    sed -e '/unit_tests=disabled/a -Ddoc=disabled \' -i distro/pkg/deb/rules && \
    sed 's/USER.*/USER = "root"/g' -i python/knot_resolver/constants.py && \
    sed 's/GROUP.*/GROUP = "root"/g' -i python/knot_resolver/constants.py && \
    git commit -a -m TMP && \
    /root/.local/bin/apkg build-dep -y && \
    /root/.local/bin/apkg build

# Stage 2: Runtime environment
FROM debian:12-slim AS runtime

# Define VERSION again as ARGs don't persist across build stages
ARG VERSION=6.0.11

# Install minimal dependencies
RUN apt-get update -qq && \
    apt-get -qqq -y install apt-transport-https ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy repository configuration from build stage
COPY --from=build \
    /usr/share/keyrings/cznic-labs-pkg.gpg \
    /usr/share/keyrings/cznic-labs-pkg.gpg
COPY --from=build \
    /etc/apt/sources.list.d/cznic-labs-knot-resolver.list \
    /etc/apt/sources.list.d/cznic-labs-knot-resolver.list

# Update packages
RUN apt-get update -qq && \
    apt-get upgrade -qq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy built packages from build stage
COPY --from=build /source/pkg/pkgs/debian-12 /pkg

# Install resolver and clean up
RUN apt-get update -qq && \
    apt-get install -y /pkg/*/*.deb && \
    rm -r /pkg && \
    apt-get remove -y -qq curl gnupg2 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration
COPY --from=build /source/etc/config/config.example.docker.yaml /etc/knot-resolver/config.yaml

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose ports for DNS, DoT, DoH and management
EXPOSE 53/UDP 53/TCP 443/TCP 853/TCP 5000/TCP

# Create volumes for configuration and cache
VOLUME /etc/knot-resolver
VOLUME /var/cache/knot-resolver

# Set entrypoint and default command
#ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
ENTRYPOINT ["/usr/bin/knot-resolver"]
CMD ["-c", "/etc/knot-resolver/config.yaml"]

# Add labels at the end to minimize rebuild impact in multi-stage builds
LABEL cz.knot-resolver.vendor="cz.nic" \
      maintainer="kometch@gmail.com" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="Knot Resolver - caching full resolver implementation"
