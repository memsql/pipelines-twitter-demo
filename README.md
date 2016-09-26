MemSQL Pipelines Twitter Demo
=============================

MemSQL has put together an example project which simulates an interesting
analytics use case using MemSQL Pipelines.

To run the demo you will need to have Docker installed and the docker
client available.


Example Usage
-------------

```bash
# Start the MemSQL container on your machine
make run-memsql

# Open up the Pipelines page on MemSQL Ops
open http://localhost:9000/data/pipelines

# Open a MemSQL client for the local MemSQL container
make sql-console

# Stop the MemSQL container when you are done
make stop-memsql
```


Running Apache Kafka Locally
----------------------------

The demo above uses a public-kafka stream provided by MemSQL which is heavily
limited and low-volume. You can circumvent that by running the Kafka stream and
associated producer locally like so:

```bash

# First we need to setup the kafka stream...

# Go to https://apps.twitter.com/ to get a set of tokens for the Twitter API.
# Then export those tokens into your environment:
# (replace TODO with the relevant token)

export TWITTER_CONSUMER_KEY=TODO
export TWITTER_CONSUMER_SECRET=TODO
export TWITTER_ACCESS_TOKEN=TODO
export TWITTER_ACCESS_SECRET=TODO

# Start the Kafka container on your machine
make run-kafka

# Then we can run the local MemSQL cluster
make run-memsql-local

# Open up the Pipelines page on MemSQL Ops
open http://localhost:9000/data/pipelines

# Open a MemSQL client for the local MemSQL container
make sql-console

# Stop the containers when you are done
make stop-memsql
make stop-kafka
```


Analysis
--------

Use `make sql-console` to inspect the database. Both pipelines should be
running, and both tables should be steadily increasing in size. See `schema.sql`
for a description of what's happening.

The following query will retrieve 10 random results along with their scoring.

```sql
SELECT
    REPLACE(text, "\n", "") AS text,
    positive, neutral, negative
FROM
    tweets t
    JOIN tweet_sentiment ts ON t.id = ts.id
ORDER BY RAND()
LIMIT 10;
```
