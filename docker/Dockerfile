FROM ubuntu:22.04 as base-image

# Install systemd
RUN apt-get update && apt-get install -y systemd systemd-sysv dbus bash-completion

# Mask a few services that we do not need
RUN systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount \
    sys-kernel-config.mount sys-kernel-debug.mount && \
    systemctl disable systemd-update-utmp.service && \
    systemctl disable systemd-tmpfiles-setup.service

# Define environment variable
ENV container docker

# Copy the systemd unit file and entry script
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN echo '\n\
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then\n\
  . /etc/bash_completion\n\
fi' >> /root/.bashrc

# Define the entry point script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["/lib/systemd/systemd"]

# Run systemd init as the main process
STOPSIGNAL SIGRTMIN+3

# Inform Docker that the container wants to run in an init system
LABEL "exec.systemd"="true"

FROM vitess/lite:v17.0.6 as binaries-image

FROM base-image as topology-image

RUN apt install -y zookeeper
COPY ./docker/topology/zookeeper.service /etc/systemd/system/
COPY ./docker/topology/env /var/lib/zookeeper/
RUN echo 1 > /etc/zookeeper/conf/myid
RUN systemctl enable zookeeper

FROM base-image as vtctl-image

RUN apt install -y netcat

RUN adduser --disabled-password --gecos "" vitess
RUN mkdir /var/log/vitess && chown vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml

COPY --from=binaries-image /vt/bin/vtctldclient /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctld /usr/local/bin/

COPY ./docker/vtctl/add_cellinfo.sh /home/vitess/
COPY ./docker/vtctl/create_keyspace.sh /home/vitess/
COPY ./docker/vtctl/set_durability_policy.sh /home/vitess/

COPY ./docker/vtctl/vtctld.service /etc/systemd/system/
COPY ./docker/vtctl/init-keyspace.service /etc/systemd/system/

RUN systemctl enable vtctld
RUN systemctl enable init-keyspace

FROM base-image as unsharded-node-image

ARG TABLET_PRIMARY_UID
ARG TABLET_REPLICA1_UID
ARG TABLET_REPLICA2_UID

RUN apt install -y mysql-server
RUN systemctl disable mysql

RUN adduser --disabled-password --gecos "" vitess

RUN mkdir -p /var/log/vitess/somecell-${TABLET_PRIMARY_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA1_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA2_UID}
RUN chown -R vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml
RUN mkdir /home/vitess/backups && chown vitess:vitess /home/vitess/backups
RUN mkdir -p /vt/vt_0000000${TABLET_PRIMARY_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA1_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA2_UID}/tmp

COPY ./docker/my.cnf /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_PRIMARY_UID}/g" /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA1_UID}/g" /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA2_UID}/g" /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf

RUN chmod -R 750 /vt && chown -R vitess:vitess /vt

COPY --from=binaries-image /vt/bin/mysqlctl /usr/local/bin/
COPY --from=binaries-image /vt/bin/vttablet /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctldclient /usr/local/bin/

COPY ./docker/vitess.sql /home/vitess/
COPY ./docker/unsharded-node/schema.sql /home/vitess/
COPY ./docker/unsharded-node/vschema.json /home/vitess/
COPY ./docker/unsharded-node/assign_primary_replica.sh /home/vitess/

COPY ./docker/unsharded-node/service/vtmysql-17${TABLET_PRIMARY_UID}.service /etc/systemd/system/
COPY ./docker/unsharded-node/service/vttablet-${TABLET_PRIMARY_UID}.service /etc/systemd/system/

COPY ./docker/unsharded-node/service/vtmysql-17${TABLET_REPLICA1_UID}.service /etc/systemd/system/
COPY ./docker/unsharded-node/service/vttablet-${TABLET_REPLICA1_UID}.service /etc/systemd/system/

COPY ./docker/unsharded-node/service/vtmysql-17${TABLET_REPLICA2_UID}.service /etc/systemd/system/
COPY ./docker/unsharded-node/service/vttablet-${TABLET_REPLICA2_UID}.service /etc/systemd/system/

COPY ./docker/unsharded-node/service/init-vtmysql.service /etc/systemd/system/
COPY ./docker/unsharded-node/service/init-vttablet.service /etc/systemd/system/

RUN systemctl enable vtmysql-17${TABLET_PRIMARY_UID}
RUN systemctl enable vttablet-${TABLET_PRIMARY_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA1_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA1_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA2_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA2_UID}

RUN systemctl enable init-vtmysql
RUN systemctl enable init-vttablet

FROM base-image as transitional-node-image

ARG TABLET_PRIMARY_UID
ARG TABLET_REPLICA1_UID
ARG TABLET_REPLICA2_UID

RUN apt install -y mysql-server
RUN systemctl disable mysql

RUN adduser --disabled-password --gecos "" vitess

RUN mkdir -p /var/log/vitess/somecell-${TABLET_PRIMARY_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA1_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA2_UID}
RUN chown -R vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml
RUN mkdir /home/vitess/backups && chown vitess:vitess /home/vitess/backups
RUN mkdir -p /vt/vt_0000000${TABLET_PRIMARY_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA1_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA2_UID}/tmp

COPY ./docker/my.cnf /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_PRIMARY_UID}/g" /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA1_UID}/g" /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA2_UID}/g" /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf

RUN chmod -R 750 /vt && chown -R vitess:vitess /vt

COPY --from=binaries-image /vt/bin/mysqlctl /usr/local/bin/
COPY --from=binaries-image /vt/bin/vttablet /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctldclient /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctlclient /usr/local/bin/

COPY ./docker/vitess.sql /home/vitess/
COPY ./docker/transitional-node/assign_primary_replica.sh /home/vitess/
COPY ./docker/transitional-node/routing_rules.json /home/vitess/

COPY ./docker/transitional-node/service/vtmysql-17${TABLET_PRIMARY_UID}.service /etc/systemd/system/
COPY ./docker/transitional-node/service/vttablet-${TABLET_PRIMARY_UID}.service /etc/systemd/system/

COPY ./docker/transitional-node/service/vtmysql-17${TABLET_REPLICA1_UID}.service /etc/systemd/system/
COPY ./docker/transitional-node/service/vttablet-${TABLET_REPLICA1_UID}.service /etc/systemd/system/

COPY ./docker/transitional-node/service/vtmysql-17${TABLET_REPLICA2_UID}.service /etc/systemd/system/
COPY ./docker/transitional-node/service/vttablet-${TABLET_REPLICA2_UID}.service /etc/systemd/system/

COPY ./docker/transitional-node/service/init-vtmysql.service /etc/systemd/system/
COPY ./docker/transitional-node/service/init-vttablet.service /etc/systemd/system/
COPY ./docker/transitional-node/service/move-tables.service /etc/systemd/system/

RUN systemctl enable vtmysql-17${TABLET_PRIMARY_UID}
RUN systemctl enable vttablet-${TABLET_PRIMARY_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA1_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA1_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA2_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA2_UID}

RUN systemctl enable init-vtmysql
RUN systemctl enable init-vttablet
RUN systemctl enable move-tables

FROM base-image as vtgate-image

RUN apt install -y mysql-client netcat

RUN adduser --disabled-password --gecos "" vitess
RUN mkdir /var/log/vitess && chown vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml

COPY --from=binaries-image /vt/bin/vtgate /usr/local/bin/

COPY ./docker/vtgate/users.json /home/vitess/
COPY ./docker/vtgate/dataset.sql /home/vitess/

COPY ./docker/vtgate/vtgate.service /etc/systemd/system/
COPY ./docker/vtgate/load-dataset.service /etc/systemd/system/

RUN systemctl enable vtgate
RUN systemctl enable load-dataset

FROM base-image as vtadmin-image

RUN apt install -y curl
RUN curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
RUN chmod +x nodesource_setup.sh
RUN bash nodesource_setup.sh
RUN apt install -y nodejs

RUN adduser --disabled-password --gecos "" vitess
RUN mkdir /var/log/vitess && chown vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml

COPY --from=binaries-image /vt/bin/vtadmin /usr/local/bin/

COPY ./docker/vtadmin/discovery.json /home/vitess/
COPY ./docker/vtadmin/rbac.yaml /home/vitess/
COPY ./docker/vtadmin/web.tar.gz /home/vitess/
RUN tar -xzvf /home/vitess/web.tar.gz -C /home/vitess/ web && rm -fr /home/vitess/web.tar.gz

COPY ./docker/vtadmin/vtadmin-api.service /etc/systemd/system/
COPY ./docker/vtadmin/vtadmin-web.service /etc/systemd/system/

RUN systemctl enable vtadmin-api
RUN systemctl enable vtadmin-web

RUN npm --prefix /home/vitess/web/vtadmin/ --silent install

ENV VITE_VTADMIN_API_ADDRESS=http://localhost:14200
ENV VITE_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS=true
RUN npm run --prefix /home/vitess/web/vtadmin/ build

FROM base-image as left-shard-node-image

ARG TABLET_PRIMARY_UID
ARG TABLET_REPLICA1_UID
ARG TABLET_REPLICA2_UID

RUN apt install -y mysql-server
RUN systemctl disable mysql

RUN adduser --disabled-password --gecos "" vitess

RUN mkdir -p /var/log/vitess/somecell-${TABLET_PRIMARY_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA1_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA2_UID}
RUN chown -R vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml
RUN mkdir /home/vitess/backups && chown vitess:vitess /home/vitess/backups
RUN mkdir -p /vt/vt_0000000${TABLET_PRIMARY_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA1_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA2_UID}/tmp

COPY ./docker/my.cnf /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_PRIMARY_UID}/g" /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA1_UID}/g" /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA2_UID}/g" /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf

RUN chmod -R 750 /vt && chown -R vitess:vitess /vt

COPY --from=binaries-image /vt/bin/mysqlctl /usr/local/bin/
COPY --from=binaries-image /vt/bin/vttablet /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctldclient /usr/local/bin/

COPY ./docker/vitess.sql /home/vitess/
COPY ./docker/left-shard-node/assign_primary_replica.sh /home/vitess/

COPY ./docker/left-shard-node/service/vtmysql-17${TABLET_PRIMARY_UID}.service /etc/systemd/system/
COPY ./docker/left-shard-node/service/vttablet-${TABLET_PRIMARY_UID}.service /etc/systemd/system/

COPY ./docker/left-shard-node/service/vtmysql-17${TABLET_REPLICA1_UID}.service /etc/systemd/system/
COPY ./docker/left-shard-node/service/vttablet-${TABLET_REPLICA1_UID}.service /etc/systemd/system/

COPY ./docker/left-shard-node/service/vtmysql-17${TABLET_REPLICA2_UID}.service /etc/systemd/system/
COPY ./docker/left-shard-node/service/vttablet-${TABLET_REPLICA2_UID}.service /etc/systemd/system/

COPY ./docker/left-shard-node/service/init-vtmysql.service /etc/systemd/system/
COPY ./docker/left-shard-node/service/init-vttablet.service /etc/systemd/system/

RUN systemctl enable vtmysql-17${TABLET_PRIMARY_UID}
RUN systemctl enable vttablet-${TABLET_PRIMARY_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA1_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA1_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA2_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA2_UID}

RUN systemctl enable init-vtmysql
RUN systemctl enable init-vttablet

FROM base-image as right-shard-node-image

ARG TABLET_PRIMARY_UID
ARG TABLET_REPLICA1_UID
ARG TABLET_REPLICA2_UID

RUN apt install -y mysql-server
RUN systemctl disable mysql

RUN adduser --disabled-password --gecos "" vitess

RUN mkdir -p /var/log/vitess/somecell-${TABLET_PRIMARY_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA1_UID}
RUN mkdir -p /var/log/vitess/somecell-${TABLET_REPLICA2_UID}
RUN chown -R vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml
RUN mkdir /home/vitess/backups && chown vitess:vitess /home/vitess/backups
RUN mkdir -p /vt/vt_0000000${TABLET_PRIMARY_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA1_UID}/tmp
RUN mkdir -p /vt/vt_0000000${TABLET_REPLICA2_UID}/tmp

COPY ./docker/my.cnf /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
COPY ./docker/my.cnf /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_PRIMARY_UID}/g" /vt/vt_0000000${TABLET_PRIMARY_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA1_UID}/g" /vt/vt_0000000${TABLET_REPLICA1_UID}/my.cnf
RUN sed -i "s/{{tablet_uid}}/${TABLET_REPLICA2_UID}/g" /vt/vt_0000000${TABLET_REPLICA2_UID}/my.cnf

RUN chmod -R 750 /vt && chown -R vitess:vitess /vt

COPY --from=binaries-image /vt/bin/mysqlctl /usr/local/bin/
COPY --from=binaries-image /vt/bin/vttablet /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctldclient /usr/local/bin/
COPY --from=binaries-image /vt/bin/vtctlclient /usr/local/bin/

COPY ./docker/vitess.sql /home/vitess/
COPY ./docker/right-shard-node/assign_primary_replica.sh /home/vitess/
COPY ./docker/right-shard-node/vschema_sharded.json /home/vitess/

COPY ./docker/right-shard-node/service/vtmysql-17${TABLET_PRIMARY_UID}.service /etc/systemd/system/
COPY ./docker/right-shard-node/service/vttablet-${TABLET_PRIMARY_UID}.service /etc/systemd/system/

COPY ./docker/right-shard-node/service/vtmysql-17${TABLET_REPLICA1_UID}.service /etc/systemd/system/
COPY ./docker/right-shard-node/service/vttablet-${TABLET_REPLICA1_UID}.service /etc/systemd/system/

COPY ./docker/right-shard-node/service/vtmysql-17${TABLET_REPLICA2_UID}.service /etc/systemd/system/
COPY ./docker/right-shard-node/service/vttablet-${TABLET_REPLICA2_UID}.service /etc/systemd/system/

COPY ./docker/right-shard-node/service/init-vtmysql.service /etc/systemd/system/
COPY ./docker/right-shard-node/service/init-vttablet.service /etc/systemd/system/
COPY ./docker/right-shard-node/service/reshard.service /etc/systemd/system/

RUN systemctl enable vtmysql-17${TABLET_PRIMARY_UID}
RUN systemctl enable vttablet-${TABLET_PRIMARY_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA1_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA1_UID}

RUN systemctl enable vtmysql-17${TABLET_REPLICA2_UID}
RUN systemctl enable vttablet-${TABLET_REPLICA2_UID}

RUN systemctl enable init-vtmysql
RUN systemctl enable init-vttablet
RUN systemctl enable reshard

FROM base-image as vtorc-image

RUN adduser --disabled-password --gecos "" vitess

RUN mkdir -p /var/log/vitess/vtorc-logs
RUN chown -R vitess:vitess /var/log/vitess
RUN touch /home/vitess/vtconfig.yaml

COPY --from=binaries-image /vt/bin/vtorc /usr/local/bin/

COPY ./docker/vtorc/vtorc.service /etc/systemd/system/

RUN systemctl enable vtorc
