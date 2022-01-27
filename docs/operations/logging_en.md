# Mariadb logging

Mariadb has an error, query, slow query and binary log.
The query and slow query log is not enabled due to privacy concerns.
The binary log provides information if Mariadb is operated in the cluster and is therefore also not relevant.
Only the error log is configured in the dogu. This also contains a warning log, which can be configured in different 
levels. A detailed explanation can be found [here](https://mariadb.com/kb/en/error-log/).

## Mapping of the ERROR WARN INFO DEBUG levels

### ERROR - 1

The log level 'ERROR' represents the levels 0 to 1 of the error log.

Messages in these class can be the following:

#### DDL error
`[Warning] InnoDB: Cannot add field col25 in table db1.tab because after adding it, the row size is 8477 which is
greater than maximum allowed size (8126) for a record on index leaf page.`

#### DNS lookup error
`[Warning] IP address '192.168.1.193' could not be resolved: Name or service not known.`

#### Event Scheduler messages
`[Note] Event Scheduler: Loaded 0 events`

### WARN - 2

The log level `WARN` represents the levels 0 to 2 of the error log.

Messages in these class can be the following:

Messages from ERROR +

#### Access Denies Errors
`[Warning] Access denied for user 'root'@'localhost' (using password: YES)`

#### Table Erros
```
[Warning] Can't find record in 'tab1'.
[Warning] Can't write; duplicate key in table 'tab1'.
[Warning] Lock wait timeout exceeded; try restarting transaction.
[Warning] The number of locks exceeds the lock table size.
[Warning] Update locks cannot be acquired during a READ UNCOMMITTED transaction.
```

### INFO - 3

The log level `INFO` represents the levels 0 to 3 of the error log.

Messages in these class can be the following:

Messages from ERROR and WARN +

#### Old-style language options
```
[Warning] An old style --language value with language specific part detected: /usr/local/mysql/data/
[Warning] Use --lc-messages-dir without language specific part instead.
```

### DEBUG - 9

The log level `DEBUG` represents the levels 0 to 9 of the error log.

Messages in these class can be the following:

messages of ERROR, WARN and INFO +

#### Killed connections
`[Warning] Aborted connection 53 to db: 'db1' user: 'user2' host: '192.168.1.50' (KILLED)`

#### Closed connections
`[Warning] Aborted connection 56 to db: 'db1' user: 'user2' host: '192.168.1.50' (CLOSE_CONNECTION)`
