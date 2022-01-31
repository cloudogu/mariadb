# Konfiguration des MariaDB-Dogu

## Voraussetzung

* MariaDB ist erfolgreich [installiert](Install_Dogu_de.md)

## Konfigurationsmöglichkeiten

Das MariaDB-Dogu wird über die Registry konfiguriert.
Es gibt mehrere Möglichkeiten, um Werte in der Registry zu konfigurieren.
Kurzgefasst kann man:
1. Ein Dogu mit `cesapp edit-config <dogu>` konfigurieren (empfohlen)
2. Die Konfigurationswerte mithilfe eines Blueprint aktualisieren
3. Die Schlüssel mit `etcdctl` manuell anpassen

## Konfiguration

Alle Konfigurationsschlüssel für die Einstellungen von MariaDB haben das Schlüsselpräfix `/config/mariadb/`.
MariaDB bietet die folgenden Einstellungen:

#### Logging-Verhalten
* Konfigurationsschlüssel-Pfad: `logging/root`
* Inhalt: Verändert das Logging-Verhalten des MariaDB-Docker-Containers. Dieser Wert wird erst nach dem Container-Neustart aktiv.
* Datentyp: String
* Valide Werte: ERROR, WARN, INFO, DEBUG
* Standardwert: ERROR
* Siehe [logging_de.md](logging_de.md)

#### Physisches Speicherlimit
* Konfigurationsschlüssel-Pfad: `container_config/memory_limit`
* Inhalt: Beschränkt den Speicher (RAM) des MariaDB-Docker-Containers. `0b` deaktiviert das Speicherlimit. Wenn dieser Wert mit einem Nicht-Null-Wert gesetzt wurde, werden 80 % des Speichers auf MariaDBs wichtigster Systemvariable `innodb_buffer_pool_size` abgebildet. Ansonsten erhält `innodb_buffer_pool_size` standardmäßig 512 MB RAM. Um diesen Wert erfolgreich anzuwenden, muss der MariaDB-Container mit `cesapp recreate` neu erzeugt werden.
* Datentyp: Binäre Speicherangabe
* Valide Werte: Ganzzahl gefolgt von [b,k,m,g] (byte, kibibyte, mebibyte, gibibyte)
* Beispiel: `1750m` = 1750 MebiByte

#### Physisches Swaplimit
* Konfigurationsschlüssel-Pfad: `container_config/swap_limit`
* Inhalt: Beschränkt den Swap des MariaDB-Docker-Containers. `0b` deaktiviert das Swaplimit.
* Datentyp: Binäre Speicherangabe
* Valide Werte: Ganzzahl gefolgt von [b,k,m,g] (byte, kibibyte, mebibyte, gibibyte)
* Beispiel: `1750m` = 1750 MebiByte


## Über das Verhalten von RAM- und Auslagerungsspeicher

### Verhalten von RAM-Konfigurationen

Wenn kein Speicherlimit gesetzt (siehe `container_config/memory_limit`) wurde, dann nimmt MariaDB 512 MB für die Systemvariable `innodb_buffer_pool_size`. Wenn andererseits ein Speicherlimit gesetzt wurde, dann werden 80 % des konfigurierten Speichers für diese Systemvariable verwendet. Weitere Informationen hierzu bietet die [MariaDB-Dokumentation](https://mariadb.com/kb/en/innodb-buffer-pool/).

### Verhalten von Auslagerungsspeicher

Wenn kein Swap-Limit (siehe `container_config/swap_limit`) oder ein Null-Wert gesetzt wurde, dann wird das Swapping-Verhalten für diesen Container abgeschaltet. Wenn ein anderer Wert gesetzt wurde, dann beeinflussen mehrere Dinge das Swapping-Verhalten.

Grundsätzlich wird das angegebene Limit auf den Container zum Zeitpunkt der Container-Erzeugung angewendet. Siehe hierzu die [Docker-Dokumentation](https://docs.docker.com/config/containers/resource_constraints/#--memory-swap-details). Zudem empfiehlt die MariaDB ein bestimmtes [`Swappiness`-Verhalten](https://mariadb.com/kb/en/configuring-swappiness/). Dieses Verhalten hängt jedoch überwiegend von der Swappiness-Konfiguration des Cloudogu EcoSystems ab. Die jeweilige Konfiguration lässt sich sowohl im Cloudogu EcoSystem mit `sysctl vm.swappiness` bzw. im MariaDB-Container mit `docker exec -it mariadb sysctl vm.swappiness` identifizieren. Aufgrund technischer Rahmenbedingungen lässt sich derzeit jedoch nicht die Swappiness von MariaDB zum Container-Startzeitpunkt automatisiert konfigurieren.