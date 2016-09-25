MEMSQL_CONTAINER = twitter-demo-memsql
TRANSFORM_BUILDER = pipelines-twitter-demo-transform


.PHONY: run-memsql
run-memsql: schema.sql transform.tar.gz
	docker run \
		-d -p 3306:3306 -p 9000:9000 \
		--name ${MEMSQL_CONTAINER} \
		-v ${PWD}/schema.sql:/schema.sql \
		-v ${PWD}/transform.tar.gz:/transform.tar.gz \
		memsql/quickstart:5.5.0-beta6


.PHONY: stop-memsql
stop-memsql: schema.sql transform.tar.gz
	docker rm -f ${MEMSQL_CONTAINER}


.PHONY: sql-console
sql-console:
	docker run \
		-it --link ${MEMSQL_CONTAINER}:memsql \
		memsql/quickstart:5.5.0-beta6 \
		memsql-shell


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
