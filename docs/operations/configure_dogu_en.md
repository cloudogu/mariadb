# Configuration of the MariaDB Dogu

## Prerequisite

* MariaDB is successfully [installed](Install_Dogu_en.md)

## Configuration options

The MariaDB-Dogu is configured via the registry.
There are several ways to configure values in the registry.
In short you can:
1. configure a dogu with `cesapp edit-config <dogu>` (recommended)
2. update the configuration values using a blueprint
3. manually adjust the keys with `etcdctl`

## Configuration

All configuration keys for MariaDB settings have the key prefix `/config/mariadb/`.
MariaDB provides the following settings:

#### logging behavior
* Configuration key path: `logging/root`
* Content: Modifies the logging behavior of the MariaDB Docker container. This value becomes active only after container restart.
* Data type: String
* Valid values: ERROR, WARN, INFO, DEBUG
* Default value: ERROR
* See [logging_en.md](logging_en.md)

#### Physical memory limit
* Configuration key path: `container_config/memory_limit`
* Content: Limits the memory (RAM) of the MariaDB Docker container. `0b` will disable swapping. If this value is set to a non-zero value, 80% of the memory is mapped to MariaDB's main system variable `innodb_buffer_pool_size`. Otherwise, `innodb_buffer_pool_size` receives 512 MB of RAM by default. To successfully apply this value, the MariaDB container must be re-created using `cesapp recreate`. 
* Data type: Binary memory specification.
* Valid values: Integer followed by [b,k,m,g] (byte, kibibyte, mebibyte, gibibyte)
* Example: `1750m` = 1750 MebiByte

#### Physical swap limit
* Configuration key path: `container_config/swap_limit`
* Content: Limits the swap of the MariaDB Docker container. `0b` will disable swapping.
* Data type: Binary storage specification.
* Valid values: Integer followed by [b,k,m,g] (byte, kibibyte, mebibyte, gibibyte)
* Example: `1750m` = 1750 MebiByte


## About RAM and swap memory behavior

### Behavior of RAM configurations

If no memory limit has been set (see `container_config/memory_limit`), then MariaDB takes 512 MB for the `innodb_buffer_pool_size` system variable. On the other hand, if a memory limit has been set, then 80 % of the configured memory is used for this system variable. See the [MariaDB documentation](https://mariadb.com/kb/en/innodb-buffer-pool/) for more information.

### Behavior of Swap memory configurations

If no swap limit (see `container_config/swap_limit`) or a zero value has been set, then swapping behavior is disabled for this container. If a different value was set, then several things affect the swapping behavior.

Basically, the specified limit is applied to the container at container creation time. See the [Docker documentation](https://docs.docker.com/config/containers/resource_constraints/#--memory-swap-details) for more information. In addition, MariaDB recommends a certain [`swappiness` behavior](https://mariadb.com/kb/en/configuring-swappiness/). However, this behavior depends predominantly on the swappiness configuration of the Cloudogu EcoSystem. The respective configuration can be identified both in the Cloudogu EcoSystem with `sysctl vm.swappiness` or in the MariaDB container with `docker exec -it mariadb sysctl vm.swappiness`. However, due to technical constraints, it is currently not possible to automatically configure the swappiness of MariaDB at container startup time.
