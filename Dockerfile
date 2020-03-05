# daemon runs in the background
# run something like tail /var/log/witchercoind/current to see the status
# be sure to run with volumes, ie:
# docker run -v $(pwd)/witchercoind:/var/lib/witchercoind -v $(pwd)/wallet:/home/witchercoin --rm -ti witchercoin:0.2.2
ARG base_image_version=0.10.0
FROM phusion/baseimage:$base_image_version

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.2.2/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

ADD https://github.com/just-containers/socklog-overlay/releases/download/v2.1.0-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /

ARG witchercoin_BRANCH=master
ENV witchercoin_BRANCH=${witchercoin_BRANCH}

# install build dependencies
# checkout the latest tag
# build and install
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      python-dev \
      gcc-4.9 \
      g++-4.9 \
      git cmake \
      libboost1.58-all-dev && \
    git clone https://github.com/witchercoin/witchercoin.git /src/witchercoin && \
    cd /src/witchercoin && \
    git checkout $witchercoin_BRANCH && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_FLAGS="-g0 -Os -fPIC -std=gnu++11" .. && \
    make -j$(nproc) && \
    mkdir -p /usr/local/bin && \
    cp src/witchercoind /usr/local/bin/witchercoind && \
    cp src/walletd /usr/local/bin/walletd && \
    cp src/zedwallet /usr/local/bin/zedwallet && \
    cp src/miner /usr/local/bin/miner && \
    strip /usr/local/bin/witchercoind && \
    strip /usr/local/bin/walletd && \
    strip /usr/local/bin/zedwallet && \
    strip /usr/local/bin/miner && \
    cd / && \
    rm -rf /src/witchercoin && \
    apt-get remove -y build-essential python-dev gcc-4.9 g++-4.9 git cmake libboost1.58-all-dev && \
    apt-get autoremove -y && \
    apt-get install -y  \
      libboost-system1.58.0 \
      libboost-filesystem1.58.0 \
      libboost-thread1.58.0 \
      libboost-date-time1.58.0 \
      libboost-chrono1.58.0 \
      libboost-regex1.58.0 \
      libboost-serialization1.58.0 \
      libboost-program-options1.58.0 \
      libicu55

# setup the witchercoind service
RUN useradd -r -s /usr/sbin/nologin -m -d /var/lib/witchercoind witchercoind && \
    useradd -s /bin/bash -m -d /home/witchercoin witchercoin && \
    mkdir -p /etc/services.d/witchercoind/log && \
    mkdir -p /var/log/witchercoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/witchercoind/run && \
    echo "fdmove -c 2 1" >> /etc/services.d/witchercoind/run && \
    echo "cd /var/lib/witchercoind" >> /etc/services.d/witchercoind/run && \
    echo "export HOME /var/lib/witchercoind" >> /etc/services.d/witchercoind/run && \
    echo "s6-setuidgid witchercoind /usr/local/bin/witchercoind" >> /etc/services.d/witchercoind/run && \
    chmod +x /etc/services.d/witchercoind/run && \
    chown nobody:nogroup /var/log/witchercoind && \
    echo "#!/usr/bin/execlineb" > /etc/services.d/witchercoind/log/run && \
    echo "s6-setuidgid nobody" >> /etc/services.d/witchercoind/log/run && \
    echo "s6-log -bp -- n20 s1000000 /var/log/witchercoind" >> /etc/services.d/witchercoind/log/run && \
    chmod +x /etc/services.d/witchercoind/log/run && \
    echo "/var/lib/witchercoind true witchercoind 0644 0755" > /etc/fix-attrs.d/witchercoind-home && \
    echo "/home/witchercoin true witchercoin 0644 0755" > /etc/fix-attrs.d/witchercoin-home && \
    echo "/var/log/witchercoind true nobody 0644 0755" > /etc/fix-attrs.d/witchercoind-logs

VOLUME ["/var/lib/witchercoind", "/home/witchercoin","/var/log/witchercoind"]

ENTRYPOINT ["/init"]
CMD ["/usr/bin/execlineb", "-P", "-c", "emptyenv cd /home/witchercoin export HOME /home/witchercoin s6-setuidgid witchercoin /bin/bash"]
