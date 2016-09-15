# TODO: use the public memsql/quickstart:5.5 tag once it is released on
# Docker Hub
FROM 798487538782.dkr.ecr.us-east-1.amazonaws.com/memsql-quickstart:5.5-beta

# transform/transform.py needs the nltk package.  Another option would be to
# vendor these libraries into the transform/ directory, so the directory can be
# tarballed and used in a MemSQL Pipeline without needing to install external
# dependencies.
RUN pip install nltk

ADD . /pipelines-example

CMD ["/pipelines-example/start.sh"]
