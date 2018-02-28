# Environment
FROM arm64v8/debian:9.3-slim
LABEL maintainer="kometchtech <kometch@gmail.com>" \
      version="github-master"
ENV DIBBLER 1.0.1
ENV DEBIAN_FRONTEND noninteractive

# config
WORKDIR /etc/dibbler
#RUN cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf
VOLUME ["/etc/dibbler"]
EXPOSE 547/TCP 547/UDP
CMD ["/usr/local/sbin/dibbler-server", "run"]

# compile and install
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends \ 
      build-essential \ 
      ca-certificates \
      coreutils \ 
      curl \ 
      automake \ 
      autoconf \ 
      unzip \
    && curl -LO "https://github.com/tomaszmrugalski/dibbler/archive/master.zip" \
    && unzip "master.zip" \ 
    && rm -f "master.zip" \
    && cd dibbler-master \
    && ./configure \ 
      #--with-gnu-ld \ 
      --sysconfdir=/etc/dibbler \ 
  && make -j "$(nproc)" \ 
  && make install \ 
  && apt-get purge -y build-essential \
  && apt-get clean \ 
  && apt-get autoremove -y \ 
  && rm -rf \ 
      "dibbler-master" \ 
      /var/lib/apt/lists/* \
  && cp /usr/local/share/doc/dibbler/examples/server.conf /etc/dibbler/server.conf
