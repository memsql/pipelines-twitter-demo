MemSQL Pipelines Example
========================

`make run logs` starts a daemon MemSQL container derived from the
`memsql/quickstart:5.5.0-beta2` Docker image.

The container runs `schema.sql`, which creates two pipelines and two destination
tables. These pipelines read from the public Kafka endpoint at
`public-kafka.memcompute.com`, using a Pipelines transform tarball hosted in S3.

Use `make mysql` to inspect the database. Both pipelines should be running, and
both tables should be steadily increasing in size. See `schema.sql` for a
description of what's happening.

Example query:
```
SELECT text, positive, neutral, negative
    FROM tweets t JOIN tweet_sentiment ts ON t.id = ts.id
    LIMIT 10 \G
```
