########################################################################
# Test for innodb_log_checksum_algorithm feature in Percona Server 5.6
########################################################################

require_xtradb
require_server_version_higher_than 5.6.13

function test_with_algorithm()
{
    vlog "################################################"
    vlog "Testing with innodb_log_checksum_algorithm=$1"
    vlog "################################################"

    MYSQLD_EXTRA_MY_CNF_OPTS="
innodb_log_checksum_algorithm=$1
"
    start_server

    # Workaround for LP bug #1247586
    $MYSQL $MYSQL_ARGS -e "SET GLOBAL innodb_log_checksum_algorithm=$1"

    load_sakila

    innobackupex --no-timestamp $topdir/backup

    egrep '^innodb_log_checksum_algorithm='$1'$' $topdir/backup/backup-my.cnf

    record_db_state sakila

    stop_server

    rm -rf $MYSQLD_DATADIR/*

    innobackupex --apply-log --defaults-file=$topdir/backup/backup-my.cnf \
                 $topdir/backup

    innobackupex --copy-back $topdir/backup

    start_server

    verify_db_state sakila

    stop_server

    rm -rf $topdir/backup
    rm -rf $MYSQLD_DATADIR
}

test_with_algorithm strict_none
test_with_algorithm strict_crc32
test_with_algorithm strict_innodb
