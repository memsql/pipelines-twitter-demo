# TODO: use the public memsql/quickstart:5.5 tag once it is released on
# Docker Hub
FROM 798487538782.dkr.ecr.us-east-1.amazonaws.com/memsql-quickstart:5.5-beta

ADD . /pipelines-example

CMD ["/pipelines-example/start.sh"]
