<?php

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

foreach ($resultList as $result) {
    echo json_encode($result, JSON_PRETTY_PRINT);
    echo sprintf('%s============================================================%s', PHP_EOL, PHP_EOL);
}
