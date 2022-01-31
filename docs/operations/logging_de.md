# MariaDB logging

MariaDB besitzt einen Error-, Query-, Slow-Query- und Binary-Log.
Das Query- und Slow-Query-Log wird wegen des Datenschutzes nicht aktiviert.
Das Binary-Log stellt Information bereit, falls Mariadb im Cluster betrieben wird und ist somit ebenfalls nicht relevant.
In dem Dogu wird ausschließlich das Error-Log konfiguriert. Dieses beinhaltet zusätzlich noch ein Warning-Log, welches
in verschiedenen Stufen konfigurierbar ist.

Eine ausführliche Erläuterung befindet sich [hier](https://mariadb.com/kb/en/error-log/).

## Mapping der Level ERROR WARN INFO DEBUG

### ERROR - [1](https://mariadb.com/kb/en/error-log/#verbosity-level-1)

Das Loglevel `ERROR` stellt die Stufen 0 bis 1 des Error-Logs dar.

Meldungen in dieser Klassen können folgende sein:

#### DDL-Fehler
`[Warning] InnoDB: Cannot add field col25 in table db1.tab because after adding it, the row size is 8477 which is 
greater than maximum allowed size (8126) for a record on index leaf page.`

#### DNS Lookup Fehler
`[Warning] IP address '192.168.1.193' could not be resolved: Name or service not known`

#### Nachrichten des Event-Schedulers
`[Note] Event Scheduler: Loaded 0 events`

### WARN - [2](https://mariadb.com/kb/en/error-log/#verbosity-level-2)

Das Loglevel `WARN` stellt die Stufen 0 bis 2 des Error-Logs dar.

Falls das Loglevel auf einen Wert gesetzt wurde, der `WARN` miteinbezieht, dann wird der Container-Health-Check alle 30 Sekunden eine Warnung wie diese generieren:
```
[Warning] Aborted connection 211 to db: 'unconnected' user: 'unauthenticated' host: '172.18.0.3' (This connection closed normally without authentication)
```

Meldungen in dieser Klassen können folgende sein:

Nachrichten von ERROR +

#### Access Denies Errors
`[Warning] Access denied for user 'root'@'localhost' (using password: YES)`

#### Table Errors
```
[Warning] Can't find record in 'tab1'.
[Warning] Can't write; duplicate key in table 'tab1'.
[Warning] Lock wait timeout exceeded; try restarting transaction.
[Warning] The number of locks exceeds the lock table size.
[Warning] Update locks cannot be acquired during a READ UNCOMMITTED transaction.
```

### INFO - [3](https://mariadb.com/kb/en/error-log/#verbosity-level-3)

Das Loglevel `INFO` stellt die Stufen 0 bis 3 des Error-Logs dar.

Meldungen in dieser Klassen können folgende sein:

Nachrichten von ERROR und WARN +

#### Old-style language options
```
[Warning] An old style --language value with language specific part detected: /usr/local/mysql/data/
[Warning] Use --lc-messages-dir without language specific part instead.
```

### DEBUG - [9](https://mariadb.com/kb/en/error-log/#verbosity-level-9)

Das Loglevel `DEBUG` stellt die Stufen 0 bis 9 des Error-Logs dar.

Meldungen in dieser Klassen können folgende sein:

Nachrichten von ERROR, WARN und INFO +

#### Killed connections
`[Warning] Aborted connection 53 to db: 'db1' user: 'user2' host: '192.168.1.50' (KILLED)`

#### Closed connections
`[Warning] Aborted connection 56 to db: 'db1' user: 'user2' host: '192.168.1.50' (CLOSE_CONNECTION)`
