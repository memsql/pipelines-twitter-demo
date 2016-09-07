#!/bin/bash
set -e
set -x

MYSQL="mysql -u root -h 127.0.0.1"
THIS_DIR="$( cd "$(dirname "$0")" && pwd -P )"

# Start up the cluster
memsql-ops start
memsql-ops memsql-start --all
memsql-ops memsql-list

# # Load schema.sql into MemSQL
$MYSQL < $THIS_DIR/schema.sql

# Tail the logs to keep the container alive
exec tail -F /memsql/master/tracelogs/memsql.log /memsql/leaf/tracelogs/memsql.log
