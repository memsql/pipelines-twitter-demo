FROM debian:8.6

RUN apt-get update && \
    apt-get install -y python-dev python-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# upgrade pip
RUN pip install -U pip
# compile the dependencies
RUN pip install --target /python_deps nltk numpy

# construct the transform
ADD . /transform

# add dependencies
RUN mv /python_deps /transform

# package the transform
RUN cd /transform && tar czf /transform.tar.gz .
