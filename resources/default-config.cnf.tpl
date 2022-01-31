[mysqld]

# according to https://mariadb.com/kb/en/configuring-mariadb-for-optimal-performance/
# the most important variables are
# - innodb_buffer_pool_size
# - innodb_log_file_size
# - innodb_flush_method
# - innodb_thread_sleep_delay

# starting with MariaDB 10.4.4 the working set in innodb_buffer_pool_size should take up to 80 % of the memory
# but at least 512 MB should be used (recommended settings vary from 2 to 16 GB depending on the actual DB server load)
# see https://wiki.alpinelinux.org/wiki/Production_DataBases_:_mysql
innodb_buffer_pool_size={{ .Env.Get "INNODB_BUFFER_POOL_SIZE_IN_BYTES"}}
innodb_log_file_size=16M

# The Performance Schema is a feature for monitoring server performance in which the DB server populates internal tables with said monitoring data.
# see https://mariadb.com/kb/en/performance-schema-overview/
performance_schema = OFF

# recommended settings by Alpine
# see https://wiki.alpinelinux.org/wiki/Production_DataBases_:_mysql
max_connections=100
max_heap_table_size=32M
tmp_table_size=32M
innodb_read_io_threads=32

# it is suggested to generally disable the query cache
# see https://mariadb.com/kb/en/query-cache/ and https://github.com/major/MySQLTuner-perl
query_cache_size=0

# disable query cache
# see: https://mariadb.com/kb/en/server-system-variables/#query_cache_type
query_cache_type=0

# Size in bytes for which results larger than this are not stored in the query cache.
# see: https://mariadb.com/kb/en/server-system-variables/#query_cache_limit
query_cache_limit=2M
