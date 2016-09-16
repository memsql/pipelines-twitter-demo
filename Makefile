IMAGE_NAME = pipelines-example


.PHONY: run
run: build rm
	docker run -d -p 3306:3306 -p 9000:9000 --name ${IMAGE_NAME} ${IMAGE_NAME}

.PHONY: build
build: transform-tar
	docker build -t ${IMAGE_NAME} .

.PHONY: rm
rm:
	docker rm -f ${IMAGE_NAME}; true

transform-tar: transform
	tar czvf transform.tar.gz transform

.PHONY: mysql
mysql:
	mysql -u root -h 127.0.0.1 example


# Docker helpers

.PHONY: logs
logs:
	docker logs -f ${IMAGE_NAME}

.PHONY: exec
exec:
	docker exec -it ${IMAGE_NAME} /bin/bash


################################################################
# PRIVATE
# Remove the following before this repo is ever moved to Github.

.PHONY: upload-transform
upload-transform: transform-tar
	aws s3 cp transform.tar.gz s3://download.memsql.com/pipelines-demo-5.5.0-beta2/transform.tar.gz

.PHONY: push
push: build
	docker tag ${IMAGE_NAME} memsql/quickstart:5.5.0-beta2-demo
	docker push memsql/quickstart:5.5.0-beta2-demo
