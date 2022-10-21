## Vitess Cluster

### Introduction
This repo is an experiment how works sharding via [Vitess](https://vitess.io).
Vitess is an application on GoLang which resolves problems if your MySQL becomes very big.
For example, it can help do MySQL sharding.
So, imagine that we have 3 tables of MySQL and 2 of them are massive.
Once we consider that to separate our 2 tables between other servers is good idea.
And now you can practice here before you're going to shard your production database.   

Here you can see how communicate containers between each other.
![This is an image](https://vitess.io/docs/14.0/overview/img/architecture.svg)
_Picture from [Vitess architecture](https://vitess.io/docs/14.0/overview/architecture/)_

So we have 9 containers that it works.

| №   | Container                                                                | Description                                                                                    |
|-----|--------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| 1   | `app` (Application)                                                      | PHP Application which make queries to Vitess.                                                  |
| 2   | [topology](https://vitess.io/docs/14.0/concepts/topology-service/)       | Helps to communicate whole parts of system between each other.                                 |
| 3   | [vtctl](https://vitess.io/docs/14.0/concepts/vtctl/)  (vtctl + vtctld)   | CLI and API service to admin a Vitess cluster.                                                 |
| 4   | [node1](https://vitess.io/docs/14.0/concepts/tablet/) (VTTablet + MySQL) | Contains an instance of a mysql and a tablet, the tablet gives queries and sends to the mysql. |
| 5   | [node2](https://vitess.io/docs/14.0/concepts/tablet/) (VTTablet + MySQL) | same like first node.                                                                          |
| 6   | [node3](https://vitess.io/docs/14.0/concepts/tablet/) (VTTablet + MySQL) | same like first node.                                                                          |
| 7   | [node4](https://vitess.io/docs/14.0/concepts/tablet/) (VTTablet + MySQL) | same like first node.                                                                          |
| 8   | [vtgate](https://vitess.io/docs/14.0/concepts/vtgate/)                   | Gives queries from application and routes that to nodes.                                       |
| 9   | [vtadmin](https://vitess.io/docs/14.0/reference/programs/vtadmin-web/)   | Web interface to view state and admin cluster.                                                 |

> Each node has three MySQL and VTTablet instances: primary, replica, rdonly.

System requirements:
* [Docker](https://www.docker.com)

Let's install our cluster!

### Installation
Build image and run.
```shell
git clone https://github.com/revilon1991/vitess-cluster.git
cd vitess-cluster
docker-compose up -d --build
```

Install `topology` staff and run.
```shell
docker-compose exec topology bash
bash /app/scripts/topology-up.sh
```

Install `vtctl` staff and run.
```shell
docker-compose exec vtctl bash
bash /app/scripts/vtctl-up.sh
```

Install `node1` staff and run MySQL and VTTablet and load sql schema.
[Keyspace](https://vitess.io/docs/14.0/concepts/keyspace/) will be `lolspace` for this node.
There will be a schema of three tables - `Device`, `User`, `RequestLog`.
```shell
docker-compose exec node1 bash
bash /app/scripts/node/reshard/node1-up.sh
```

Install `vtgate` staff and load sql dataset and users.
Dataset will be load to keyspace `lolspace` for all tables.
```shell
docker-compose exec vtgate bash
bash /app/scripts/vtgate-up.sh
```

Install `node2` staff and run MySQL and VTTablet and load sql dataset and users.
This node will be in new `kekspace` keyspace.
It's node for migration two tables `Device`, `User` from `lolspace` keyspace.
As well, we'll switch traffic on `Device` and `User` tables to new `kekspace` keyspace.
Traffic on table `RequestLog` keeps on `lolspace` keyspace.
That action name is [MoveTables](https://vitess.io/docs/14.0/user-guides/migration/move-tables/). 
Actual, it needs for [vertical sharding](https://vitess.io/docs/14.0/user-guides/historical/vertical-split/) or preparing to [horizontal sharding](https://vitess.io/docs/14.0/user-guides/historical/horizontal-sharding/).
```shell
docker-compose exec node2 bash
bash /app/scripts/node/reshard/node2-up.sh
```

Install `node3` staff and run MySQL and VTTablet in keyspace `kekspace`.
After that we'll make new shard which will be contained ~50% data from `Device` and `User` tables.
The data have not been migrated from `node2` yet. It'll happen after initialing `node4`.
Now the traffic for `Device` and `User` going only to `node2` of `kekspace` keyspace.
```shell
docker-compose exec node3 bash
bash /app/scripts/node/reshard/node3-up.sh
```

Install `node4` staff and run MySQL and VTTablet in keyspace `kekspace`.
After that we'll make else once shard which will be contained second ~50% part of data from `Device` and `User` tables.
Now the data have been successfully migrated and sharded from `node2` to `node3` and `node4`.
The traffic also was switched between `node3` and `node4`.
The metadata from `node2` for a topology was deleted but the data you should remove by yourself.
Also, we'll set [vindex](https://vitess.io/docs/14.0/reference/features/vindexes/) (sharding key) config.
```shell
docker-compose exec node4 bash
bash /app/scripts/node/reshard/node4-up.sh
```

Install `vtadmin` staff and run `NodeJS` server with web interface.
After install you can research your own cluster here http://localhost:14201/schemas
```shell
docker-compose exec vtadmin bash
bash /app/scripts/vtadmin-up.sh
```

### Usage
Let's see how it works from simple PHP application.
```shell
docker-compose exec app bash
docker-php-ext-install pdo_mysql
php /app/index.php
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
You can see those [here](https://vitess.io/docs/14.0/reference/compatibility/mysql-compatibility/)

More information at [Vitess Documentation](https://vitess.io/docs/14.0/).

License
-------

[![license](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](./LICENSE)