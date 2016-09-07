#!/usr/bin/python

import json
import struct
import sys


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


for bytes in transform_records():
    #  data = json.loads(bytes)
    #  text = data["text"]

    out = b"\\u00e9\n" % text
    sys.stdout.write(out)


    #  if "text" not in data:
        #  sys.stderr.write("'text' field missing from Twitter JSON message")
    #  else:
        #  # Use 'json.dumps' to wrap in quotes and also escape quotes in the text
        #  # itself. This maintains the contract that we are sending CSV with
        #  # FIELDS TERMINATED BY "," ENCLOSED BY "\"" ESCAPED BY "\\", as we
        #  # specified in schema.sql
        #  out = '%s\n' % json.dumps(data["text"], encoding="utf-8")
        #  #  out = "foo\n"
        #  sys.stdout.write(out)
