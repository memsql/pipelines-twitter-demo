#!/bin/bash

KAFKA_HOST="$KAFKA_PORT_9092_TCP_ADDR"

sed "s_public-kafka.memcompute.com:9092/tweets-json_$KAFKA_HOST/tweets-json_" /schema.sql.tpl > /schema.sql

exec /memsql-entrypoint.sh memsqld
