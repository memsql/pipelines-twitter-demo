FROM memsql/quickstart:5.5-beta2

# transform/transform.py needs the nltk package.  Another option would be to
# vendor these libraries into the transform/ directory, so the directory can be
# tarballed and used in a MemSQL Pipeline without needing to install external
# dependencies.
RUN pip install nltk

ADD . /pipelines-example

CMD ["/pipelines-example/start.sh"]
