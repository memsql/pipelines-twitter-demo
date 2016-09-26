MemSQL Pipelines Twitter Demo
=============================

Here is an example project that demonstrates an interesting
analytics use case using MemSQL Pipelines. Specifically, this demo captures
tweets and retweet counts for posts pretaining to Hillary and Trump, 
the 2016 US presidential nominees.  

To run the demo you will need to have Docker installed and the docker
client available.


Example Usage
-------------

```bash
# Start the MemSQL container on your machine
make run-memsql

# Open up the Pipelines page on MemSQL Ops
# Note that your hostname may be different if you are using Docker Toolbox or similar software
open http://localhost:9000/data/pipelines

# Open a MemSQL client for the local MemSQL container
make sql-console

# Stop the MemSQL container when you are done
make stop-memsql
```


Running Apache Kafka Locally
----------------------------

Running the demo using the base instructions above will use a public-kafka stream provided by MemSQL which is heavily
limited and low in data stream volume. You can circumvent this by choosing to run the Kafka stream and
associated producer with Docker in your local environment, like so:

```bash

# First we need to setup the Kafka stream...

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
# Note that your hostname may be different if you are using Docker Toolbox or similar software
open http://localhost:9000/data/pipelines

# Open a MemSQL client for the local MemSQL container
make sql-console

# Stop the containers when you are done
make stop-memsql
make stop-kafka
```


Running Analytical Queries on the Data Set
------------------------------------------

Use `make sql-console` to open a SQL prompt into the MemSQL Database 
that is running the twitter pipelines. You should notice two pipelines running -
`twitter_pipeline` and `twitter_sentiment_pipeline`. You should also notice 
two tables where these pipelines store data -
`tweets` and `tweet_sentiment`, which are steadily increasing in size. 
See `schema.sql`to see exactly how the pipelines and tables are defined.

Within the MemSQL Database, you run simple analytical queries on 
the `tweets` and `tweet_sentiment` tables. For example, 
the following query will retrieve 10 random tweets about Hillary or Trump
and show the tweet's sentiment - positive, negative or neutral.

```sql
SELECT
    REPLACE(text, "\n", "") AS text,
    positive, neutral, negative
FROM
    example.tweets t
    JOIN example.tweet_sentiment ts ON t.id = ts.id
ORDER BY RAND()
LIMIT 10\G
```
