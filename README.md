MemSQL Pipelines Twitter Demo
=============================

MemSQL has put together an example project which simulates an interesting
analytics use case using MemSQL Pipelines.

To run the demo locally you will need to have Docker installed and the docker
client available. The demo runs two containers: one for Apache Kafka and one
for MemSQL.


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
