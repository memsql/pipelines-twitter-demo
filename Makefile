MEMSQL_CONTAINER = twitter-demo-memsql
KAFKA_CONTAINER = twitter-demo-kafka
TRANSFORM_BUILDER = pipelines-twitter-demo-transform


.PHONY: run-memsql
run-memsql: schema.sql
	docker run \
		-d -p 3306:3306 -p 9000:9000 \
		--name ${MEMSQL_CONTAINER} \
		-v ${PWD}/schema.sql:/schema.sql \
		memsql/quickstart:5.5.0-beta6


.PHONY: run-kafka
run-kafka:
	docker run --name ${KAFKA_CONTAINER} \
		-d -p 9092:9092 -p 2181:2181 \
		-e PRODUCE_TWITTER=1 \
		-e TWITTER_CONSUMER_KEY \
		-e TWITTER_CONSUMER_SECRET \
		-e TWITTER_ACCESS_TOKEN \
		-e TWITTER_ACCESS_SECRET \
		memsql/kafka


.PHONY: stop-kafka
stop-kafka:
	docker rm -f ${KAFKA_CONTAINER}


.PHONY: run-memsql-local
run-memsql-local: schema.sql
	docker run \
		-d -p 3306:3306 -p 9000:9000 \
		--name ${MEMSQL_CONTAINER} \
		--link ${KAFKA_CONTAINER}:kafka \
		-v ${PWD}/scripts/start_with_local_kafka.sh:/start.sh \
		-v ${PWD}/schema.sql:/schema.sql.tpl \
		memsql/quickstart:5.5.0-beta6 /start.sh


.PHONY: stop-memsql
stop-memsql:
	docker rm -f ${MEMSQL_CONTAINER}


.PHONY: sql-console
sql-console:
	docker run \
		-it --link ${MEMSQL_CONTAINER}:memsql \
		memsql/quickstart:5.5.0-beta6 \
		memsql-shell


# You can use this target to build your own transform and upload it somewhere
# (or mount it in the container)
transform.tar.gz: transform
	docker build -t ${TRANSFORM_BUILDER} transform
	@-docker rm ${TRANSFORM_BUILDER} >/dev/null 2>&1
	docker create --name ${TRANSFORM_BUILDER} ${TRANSFORM_BUILDER}
	docker cp ${TRANSFORM_BUILDER}:transform.tar.gz transform.tar.gz
	docker rm ${TRANSFORM_BUILDER}


################################################################
# Deployment targets
# Must have access to the MemSQL organization on Docker Hub and
# access to uploading files to the MemSQL S3 download bucket.

.PHONY: upload-transform
upload-transform: transform.tar.gz
	aws s3api put-object \
		--bucket download.memsql.com \
		--key pipelines-twitter-demo/transform.tar.gz \
		--acl public-read \
		--body transform.tar.gz
