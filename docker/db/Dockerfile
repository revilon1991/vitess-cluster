FROM ubuntu:22.04

ENV version=14.0.2
ENV hash=4d94e3f
ENV file=vitess-${version}-${hash}.tar.gz
ENV dir=vitess-${version}-${hash}
ENV user=vitess

# Install system dependences
RUN apt update && apt install -y sudo mysql-server etcd curl nano wget git syslog-ng-core

# Install node
RUN curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
RUN chmod +x nodesource_setup.sh
RUN sudo bash nodesource_setup.sh
RUN sudo apt-get install -y nodejs

## Add user
RUN useradd -rm -d /home/${user} -s /bin/bash -g root -G sudo -u 1001 -p '' ${user}
RUN echo 'export PATH=/usr/local/vitess/bin:${PATH}' >> /home/${user}/.bashrc

## Install vitess
RUN wget https://github.com/vitessio/vitess/releases/download/v${version}/${file}
RUN tar -xzf ${file}
RUN mkdir -p /usr/local/vitess
RUN cd ${dir} && cp -r * /usr/local/vitess/
RUN mkdir -p /home/${user}/vitess
RUN cp -r /usr/local/vitess/examples/local/* /home/${user}/vitess
RUN cd /tmp && git clone --progress https://github.com/vitessio/vitess.git
RUN cd /tmp/vitess && git checkout tags/v14.0.2 -b v14.0.2-branch
RUN mkdir -p /home/web/
RUN cp -r /tmp/vitess/web/vtadmin /home/web/
RUN echo 'TOPOLOGY_FLAGS="${TOPOLOGY_FLAGS} --mysql_server_version=8.0.30"' >> /home/vitess/vitess/env.sh

RUN chown -R ${user}:sudo /home/
WORKDIR /home/${user}
USER ${user}

# Entrypoint
COPY ./entrypoint.sh /
RUN sudo chmod +x /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
