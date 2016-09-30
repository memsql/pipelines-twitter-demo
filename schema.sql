DROP DATABASE IF EXISTS example;
CREATE DATABASE example;
USE example;


-- A table set up to receive raw data from Kafka.
CREATE TABLE tweets (

    -- These fields are present in each record we get from Kafka. `tweet` is an
    -- arbitrary JSON blob.
    id BIGINT,
    ts TIMESTAMP,
    tweet JSON,

    -- These are examples of computed columns. We use MemSQL JSON subselect
    -- syntax to create extra columns derived from `tweet`.
    text AS tweet::$text PERSISTED TEXT,
    retweet_count AS tweet::%retweet_count PERSISTED INT,
    candidate AS CASE
        WHEN (text LIKE '%illary%') THEN 'Clinton'
        WHEN (text LIKE '%linton%') THEN 'Clinton'
        WHEN (text LIKE '%onald%') THEN 'Trump'
        WHEN (text LIKE '%rump%') THEN 'Trump'
        ELSE 'Unknown' END PERSISTED TEXT,
    created AS FROM_UNIXTIME(`tweet`::$created_at) PERSISTED DATETIME,

    KEY(id) USING CLUSTERED COLUMNSTORE,
    SHARD KEY(id)
);


-- A MemSQL Pipeline. Everything inside "CREATE PIPELINE AS" is a normal "LOAD
-- DATA" statement.
CREATE PIPELINE twitter_pipeline AS

    -- The "source" of this pipeline is a Kafka broker and topic.
    LOAD DATA KAFKA "public-kafka.memcompute.com:9092/tweets-json"

    -- The "sink" of this pipeline is a MemSQL Table. In this case, our
    -- destination table has a unique key, so we REPLACE rows if we get a new
    -- record with a key that already exists in the table.
    INTO TABLE tweets

    -- Our example Kafka topic contains tab-separated data: a tweet ID, and a
    -- JSON blob representing a tweet.
    FIELDS TERMINATED BY "\t"

    -- Our tab-separated data from Kafka will be written to these two columns in
    -- the destination table.
    (id, tweet);


-- A table of sentiment score by tweet ID.
CREATE TABLE tweet_sentiment (
    id BIGINT,

    -- These fields are outputted by the sentiment analyzer. "compound" ranges
    -- from -1 to 1 and generally represents sentiment on a scale of "bad" to
    -- "good". The other three numbers each range from 0 to 1 and together give
    -- a more precise picture of the detected sentiment.
    compound FLOAT,
    positive FLOAT,
    negative FLOAT,
    neutral FLOAT,

    KEY(id) USING CLUSTERED COLUMNSTORE,
    SHARD KEY(id)
);

-- A MemSQL Pipeline with a transform
CREATE PIPELINE twitter_sentiment_pipeline AS
    LOAD DATA KAFKA "public-kafka.memcompute.com:9092/tweets-json"

    -- Here, we specify an executable that will transform each record that
    -- passes through the Pipeline. In this case, our transform function takes
    -- JSON blobs from Twitter and performs a sentiment analysis on the tweet
    -- text, returning a tweet ID and a score.
    -- passes through the Pipeline. In this case, our transform function takes
    -- JSON blobs from Twitter and performs a sentiment analysis on the tweet
    -- text, returning a tweet ID and a score.
    -- WITH TRANSFORM (
    --     "file://localhost/transform.tar.gz",
    --     "transform.py", "")

    -- The transform can also be downloaded from a url
    WITH TRANSFORM (
        "http://download.memsql.com/pipelines-twitter-demo/transform.tar.gz",
        "transform.py", "")

    INTO TABLE tweet_sentiment
    FIELDS TERMINATED BY "\t"
    (id, compound, positive, negative, neutral);


CREATE VIEW tweet_scores AS
SELECT
    t.id, t.tweet, t.text, t.retweet_count,
    t.ts, t.candidate, ts.compound,
    ts.positive, ts.negative, ts.neutral
FROM
    tweets AS t
    INNER JOIN tweet_sentiment AS ts
    ON t.id = ts.id;


CREATE VIEW tweets_per_candidate as
SELECT
    FORMAT(COUNT(*), 0) tweet_scores, candidate
FROM tweet_scores t
GROUP BY candidate;


CREATE VIEW tweets_per_sentiment_per_candidate_timeseries AS
SELECT
    FROM_UNIXTIME(TRUNCATE(UNIX_TIMESTAMP(ts) / 60, 0) * 60) AS ts_bucket,
    TRUNCATE(compound, 1) AS sentiment_bucket,
    FORMAT(COUNT(*), 0) AS tweet_volume,
    candidate
FROM tweet_scores t
GROUP BY ts_bucket, sentiment_bucket, candidate;


CREATE VIEW sentiment_histogram AS
SELECT
    sentiment_bucket,
    SUM(IF(candidate = "Clinton", tweet_volume, 0)) as clinton_tweets,
    SUM(IF(candidate = "Trump", tweet_volume, 0)) as trump_tweets
FROM tweets_per_sentiment_per_candidate_timeseries t
GROUP BY sentiment_bucket
ORDER BY sentiment_bucket;


CREATE VIEW timeseries_histogram AS
SELECT
    ts_bucket,
    SUM(IF(candidate = "Clinton", tweet_volume, 0)) as clinton_tweets,
    SUM(IF(candidate = "Trump", tweet_volume, 0)) as trump_tweets
FROM tweets_per_sentiment_per_candidate_timeseries t
GROUP BY ts_bucket
ORDER BY ts_bucket;


-- We make sure that our pipelines do not start reading the Kafka topic from the
-- beginning; instead, they starts reading new data as it comes in.
ALTER PIPELINE twitter_pipeline SET OFFSETS LATEST;
ALTER PIPELINE twitter_sentiment_pipeline SET OFFSETS LATEST;

START PIPELINE twitter_pipeline;
START PIPELINE twitter_sentiment_pipeline;
