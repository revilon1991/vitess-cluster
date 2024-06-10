# This file is executed immediately after mysql_install_db,
# to initialize a fresh data directory.
###############################################################################
# Equivalent of mysql_secure_installation
###############################################################################
# We need to ensure that super_read_only is disabled so that we can execute
# these commands. Note that disabling it does NOT disable read_only.
# We save the current value so that we only re-enable it at the end if it was
# enabled before.
set @original_super_read_only = if(@@global.super_read_only = 1, 'ON', 'OFF');
set global super_read_only = 'OFF';
# Changes during the init db should not make it to the binlog.
# They could potentially create errant transactions on replicas.
set sql_log_bin = 0;
# Remove anonymous users.
delete
from mysql.user
where User = '';
# Disable remote root access (only allow UNIX socket).
delete
from mysql.user
where User = 'root'
  and Host != 'localhost';
# Remove test database.
drop database if exists test;
###############################################################################
# Vitess defaults
###############################################################################
# Vitess-internal database.
create database if not exists _vt;
# Note that definitions of local_metadata and shard_metadata should be the same
# as in production which is defined in go/vt/mysqlctl/metadata_tables.go.
create table if not exists _vt.local_metadata
(
    name    varchar(255)   not null,
    value   varchar(255)   not null,
    db_name varbinary(255) not null,
    primary key (db_name, name)
) engine = InnoDB;
create table if not exists _vt.shard_metadata
(
    name    varchar(255)   not null,
    value   mediumblob     not null,
    db_name varbinary(255) not null,
    primary key (db_name, name)
) engine = InnoDB;
# Admin user with all privileges.
create user 'vt_dba'@'localhost';
grant all on *.* to 'vt_dba'@'localhost';
grant grant option on *.* to 'vt_dba'@'localhost';
# User for app traffic, with global read-write access.
create user 'vt_app'@'localhost';
grant select, insert, update, delete, create, drop, reload, process, file,
    references, index, alter, show databases, create temporary tables,
    lock tables, execute, replication client, create view, show view,
    create routine, alter routine, create user, event, trigger
    on *.* to 'vt_app'@'localhost';
# User for app debug traffic, with global read access.
create user 'vt_appdebug'@'localhost';
grant select, show databases, process on *.* to 'vt_appdebug'@'localhost';
# User for administrative operations that need to be executed as non-SUPER.
# Same permissions as vt_app here.
create user 'vt_allprivs'@'localhost';
grant select, insert, update, delete, create, drop, reload, process, file,
    references, index, alter, show databases, create temporary tables,
    lock tables, execute, replication slave, replication client, create view,
    show view, create routine, alter routine, create user, event, trigger
    on *.* to 'vt_allprivs'@'localhost';
# User for slave replication connections.
# TODO: Should we set a password on this since it allows remote connections?
create user 'vt_repl'@'%';
grant replication slave on *.* to 'vt_repl'@'%';
# User for Vitess VReplication (base vstreamers and vplayer).
create user 'vt_filtered'@'localhost';
grant select, insert, update, delete, create, drop, reload, process, file,
    references, index, alter, show databases, create temporary tables,
    lock tables, execute, replication slave, replication client, create view,
    show view, create routine, alter routine, create user, event, trigger
    on *.* to 'vt_filtered'@'localhost';
flush privileges;
reset slave all;
reset master;

###############################################################################
# Custom users
###############################################################################

###############################################################################

# App database.
# Actually instead of this you should replicate your common mysql through unmanaged tablet to vitess
# or restore your DB from the backup by tablet flag --restore_from_backup
create database if not exists vt_unsharded;
create database if not exists vt_sharded;

# We need to set super_read_only back to what it was before
set global super_read_only = ifnull(@original_super_read_only, 'ON');
