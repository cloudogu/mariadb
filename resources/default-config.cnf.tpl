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

#join_buffer_size=1M
#sort_buffer_size=1M
#read_buffer_size=1M
max_connections=100
tmp_table_size=32M
max_heap_table_size=32M
innodb_file_format=Barracuda
innodb_large_prefix=1
innodb_read_io_threads=32
performance_schema = ON enable PFS

# it is suggested to generally disable the query cache
# see https://mariadb.com/kb/en/query-cache/ and https://github.com/major/MySQLTuner-perl
query_cache_size=0

# disable query cache
# see: https://mariadb.com/kb/en/server-system-variables/#query_cache_type
query_cache_type=0

# Size in bytes for which results larger than this are not stored in the query cache.
# see: https://mariadb.com/kb/en/server-system-variables/#query_cache_limit
query_cache_limit=2M
