## Vitess Cluster

### Introduction
This repo is an experiment how works sharding via [Vitess](https://vitess.io).
Vitess is an application on GoLang which resolves problems if your MySQL becomes very big.
For example, it can help do MySQL sharding.
So, imagine that we have 3 tables of MySQL and 2 of them are massive.
Once we consider that to separate our 2 tables between other servers is good idea.
And now you can practice here before you're going to shard your production database.

Here you can see how communicate containers between each other.

![This is an image](https://vitess.io/docs/17.0/overview/img/architecture.svg)

_Picture from [Vitess architecture](https://vitess.io/docs/17.0/overview/architecture/)_

So we have 9 containers that it works.

| № | Container                                                                            | Description                                                    |
|---|--------------------------------------------------------------------------------------|----------------------------------------------------------------|
| 1 | `app` (Application)                                                                  | PHP Application which make queries to Vitess.                  |
| 2 | [topology](https://vitess.io/docs/17.0/concepts/topology-service/)                   | Helps to communicate whole parts of system between each other. |
| 3 | [vtctl](https://vitess.io/docs/17.0/concepts/vtctl/)  (vtctl + vtctld)               | CLI and API service to admin a Vitess cluster.                 |
| 4 | [unsharded-node](https://vitess.io/docs/17.0/concepts/tablet/) (VTTablet + MySQL)    | Serve unsharded data.                                          |
| 5 | [transitional-node](https://vitess.io/docs/17.0/concepts/tablet/) (VTTablet + MySQL) | Assist in transferring data to the sharded space.              |
| 6 | [left-shard-node](https://vitess.io/docs/17.0/concepts/tablet/) (VTTablet + MySQL)   | First shard with data.                                         |
| 7 | [right-shard-node](https://vitess.io/docs/17.0/concepts/tablet/) (VTTablet + MySQL)  | Second shard with data.                                        |
| 8 | [vtgate](https://vitess.io/docs/17.0/concepts/vtgate/)                               | Serve SQL queries.                                             |
| 9 | [vtadmin](https://vitess.io/docs/17.0/reference/programs/vtadmin-web/)               | GUI.                                                           |
| 9 | [vtorc](https://vitess.io/docs/17.0/user-guides/configuration-basic/vtorc/)          | Automated fault detection and repair tool.                     |

> Each node has three MySQL and VTTablet instances: primary, replica, replica with semi sync replication.

System requirements:
* [Docker](https://www.docker.com)

Let's install our cluster!

### Installation
Just run.
```shell
git clone https://github.com/revilon1991/vitess-cluster.git
cd vitess-cluster
docker-compose up -d
```
##### The explanation what happens while containers is going up.
Container `unsharded-node` run MySQL and VTTablet and load sql schema.
[Keyspace](https://vitess.io/docs/17.0/concepts/keyspace/) will be `unsharded` for this node.
There will be a schema of three tables - `Device`, `User`, `RequestLog`.

Container `vtgate` load sql dataset and users.
Dataset will be load to keyspace `unsharded` for all tables.

Container `transitional-node` run MySQL and VTTablet.
This node will be in new `sharded` keyspace.
It's node for migration two tables `Device`, `User` from `unsharded` keyspace.
As well, we'll switch traffic on `Device` and `User` tables to new `sharded` keyspace.
Traffic on table `RequestLog` keeps on `unsharded` keyspace.
That action name is [MoveTables](https://vitess.io/docs/17.0/user-guides/migration/move-tables/).
Actual, it needs for [vertical sharding](https://vitess.io/docs/17.0/reference/features/sharding/) or preparing to [horizontal sharding](https://vitess.io/docs/17.0/reference/features/sharding/).

Container `left-shard-node` run MySQL and VTTablet in keyspace `sharded`.
After that we'll make new shard which will be contained ~50% data from `Device` and `User` tables.
The data have not been migrated from `transitional-node` yet. It'll happen after initialing `right-shard-node`.
Now the traffic for `Device` and `User` going only to `transitional-node` of `sharded` keyspace.

Container `right-shard-node` run MySQL and VTTablet in keyspace `sharded`.
After that we'll make else once shard which will be contained second ~50% part of data from `Device` and `User` tables.
Now the data have been successfully migrated and sharded from `transitional-node` to `left-shard-node` and `right-shard-node`.
The traffic also was switched between `left-shard-node` and `right-shard-node`.
The metadata from `transitional-node` for a topology was deleted but the data you should remove by yourself.
Also, we'll set [vindex](https://vitess.io/docs/17.0/reference/features/vindexes/) (sharding key) config.

Container `vtadmin` run `NodeJS` server with web interface and run API server Vitess.
You can research your own cluster here http://localhost:14201/tablets

Container `vtorc` run orchestrator. It help to keep your cluster healthy.
Here http://localhost:16000/debug/status you can see recent recoveries.

### Usage
Let's see how it works from simple PHP application.
```shell
docker-compose exec app ash
php index.php
```

There just connection to database (VTGate) and one query with join on all tables.
```php
$dsn = 'mysql:host=vtgate;port=15306';
$user = 'admin';
$password = 'admin';
$pdo = new PDO($dsn, $user, $password);

$sql = <<<SQL
select
    *
from Device d
inner join User u on u.id = d.userId
left join RequestLog rl on rl.createdAt = d.createdAt
SQL;

$stmt = $pdo->query($sql);
$resultList = $stmt->fetchAll(PDO::FETCH_ASSOC);

var_dump($resultList);
// here will be all data Device, User from all shards and data from our first keyspace from table RequestLog.
```
Change it, and you'll be able to do some experiments.

So, you could look that application doesn't mind about shard that just make queries.
Vitess is doing all the work of merging data.
Of course some restrictions is.
You can see those [here](https://vitess.io/docs/17.0/reference/compatibility/mysql-compatibility/)

### Useful
| №  | Service                                    | URL                                 |
|----|--------------------------------------------|-------------------------------------|
| 1  | Tablet 101 - primary unsharded DB          | http://localhost:15101/debug/status |
| 2  | Tablet 102 - replica unsharded DB          | http://localhost:15102/debug/status |
| 3  | Tablet 103 - replica unsharded DB          | http://localhost:15103/debug/status |
| 4  | Tablet 201 - primary transition sharded DB | http://localhost:15201/debug/status |
| 5  | Tablet 202 - replica transition sharded DB | http://localhost:15202/debug/status |
| 6  | Tablet 203 - replica transition sharded DB | http://localhost:15203/debug/status |
| 7  | Tablet 301 - primary left shard DB         | http://localhost:15301/debug/status |
| 8  | Tablet 302 - replica left shard DB         | http://localhost:15302/debug/status |
| 9  | Tablet 303 - replica left shard DB         | http://localhost:15303/debug/status |
| 10 | Tablet 401 - primary right shard DB        | http://localhost:15401/debug/status |
| 11 | Tablet 402 - replica right shard DB        | http://localhost:15402/debug/status |
| 12 | Tablet 403 - replica right shard DB        | http://localhost:15403/debug/status |
| 13 | Orchestrator                               | http://localhost:16000/debug/status |
| 14 | GUI                                        | http://localhost:14201/tablets      |

More information at [Vitess Documentation](https://vitess.io/docs/17.0/).

License
-------

[![license](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](./LICENSE)
