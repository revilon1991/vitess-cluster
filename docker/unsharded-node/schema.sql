create table if not exists User
(
    id        bigint unsigned not null,
    name      varchar(255),
    createdAt datetime,
    primary key (id),
    index idxCreatedAt (createdAt)
);

create table if not exists Device
(
    id        bigint unsigned not null,
    os        enum ('iOS', 'Android'),
    bundleId  varchar(50),
    installId varchar(100),
    active    bool default true,
    userId    bigint unsigned not null,
    createdAt datetime,
    primary key (id),
    index idxCreatedAt (createdAt),
    index idxUserId (userId),
    index idxBundleIdOs (bundleId, os)
);

create table if not exists RequestLog
(
    id        bigint unsigned not null,
    request   longtext,
    response  longtext,
    createdAt datetime,
    primary key (id),
    index idxCreatedAt (createdAt)
);
