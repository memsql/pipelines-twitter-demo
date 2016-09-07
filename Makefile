IMAGE_NAME = pipelines-example

.PHONY: build
build:
	docker build --no-cache -t ${IMAGE_NAME} .

.PHONY: run
run:
	docker run -d -p 3306:3306 -p 9000:9000 --name ${IMAGE_NAME} ${IMAGE_NAME}

.PHONY: rm
rm:
	docker rm -f ${IMAGE_NAME}

.PHONY: mysql
mysql:
	mysql -u root -h 127.0.0.1 example
