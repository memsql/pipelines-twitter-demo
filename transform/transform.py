#!/usr/bin/python

import json
import os
import struct
import sys

# dependencies are stored in a folder called python_deps
# relative to this script. This is setup by the Dockerfile.

SCRIPT_DIR = os.path.join(os.path.dirname(__file__))
sys.path.append(os.path.join(SCRIPT_DIR, "python_deps"))

# Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious
# Rule-based Model for Sentiment Analysis of Social Media Text.
# Eighth International Conference on Weblogs and Social Media
# (ICWSM-14). Ann Arbor, MI, June 2014.
from nltk.sentiment.vader import SentimentIntensityAnalyzer

# This class uses a file that we included in the transform tarball that we put
# in the 'WITH TRANSFORM' statement.
LEXICON_LOCAL_PATH = "vader_sentiment_lexicon.txt"
LEXICON_PATH = os.path.join(SCRIPT_DIR, LEXICON_LOCAL_PATH)

# A text sentiment analyzer that doesn't require a training step.
MODEL = SentimentIntensityAnalyzer(lexicon_file=LEXICON_PATH)


# This is a bit of boilerplate that handles the way that incoming records are
# encoded. Data is streamed to stdin, and each record is prefixed with 8 bytes
# indicating how long the record is. This Python generator reads individual
# records and yields them one by one.
def transform_records():
    while True:
        byte_len = sys.stdin.read(8)
        if len(byte_len) == 8:
            byte_len = struct.unpack("L", byte_len)[0]
            result = sys.stdin.read(byte_len)
            yield result
        else:
            assert len(byte_len) == 0, byte_len
            return


# Iterate over the records that we receive from Kafka.
for bytes in transform_records():

    # Parse the tab-separated record.
    (id, tweet_str) = bytes.split("\t")

    # Convert the tweet JSON blob from double-escaped to single-escaped, so we
    # can parse it.
    tweet = json.loads(tweet_str.replace('\\\\', '\\'))

    # Extract the text from the tweet, and run it through the sentiment model.
    text = tweet["text"]
    scores = MODEL.polarity_scores(text)

    # Output, in tab-separated format with a newline at the end, the tweet ID
    # plus all of the fields returned by the sentiment analyzer.
    out_record = (
        id, scores["compound"], scores["pos"], scores["neg"], scores["neu"])

    out_str = "\t".join([str(field) for field in out_record])
    out = b"%s\n" % out_str

    sys.stdout.write(out)
