CREATE DATABASE `example`;
USE `example`;


-- A table set up to receive raw data from Kafka.
CREATE TABLE `tweets` (

    -- These two fields are present in each record we get from Kafka. `tweet` is
    -- an arbitrary JSON blob.
    `id` BIGINT PRIMARY KEY,
    `tweet` JSON,

    -- These are examples of computed columns. We use MemSQL JSON subselect
    -- syntax to create extra columns derived from `tweet`.
    `text` AS `tweet`::$text PERSISTED TEXT,
    `retweet_count` AS `tweet`::%retweet_count PERSISTED INT
);


-- A MemSQL Pipeline. Everything inside "CREATE PIPELINE AS" is a normal "LOAD
-- DATA" statement.
CREATE PIPELINE `twitter_pipeline` AS

    -- The "source" of this pipeline is a Kafka broker and topic.
    -- [TODO: give it a domain name. I'll do that once I lock it down.]
    LOAD DATA KAFKA "public-kafka.memcompute.com:9092/tweets-json"

    -- The "sink" of this pipeline is a MemSQL Table. In this case, our
    -- destination table has a unique key, so we REPLACE rows if we get a new
    -- record with a key that already exists in the table.
    REPLACE INTO TABLE `tweets`

    -- Our example Kafka topic contains tab-separated data: a tweet ID, and a
    -- JSON blob representing a tweet.
    FIELDS TERMINATED BY "\t"

    -- Our tab-separated data from Kafka will be written to these two columns in
    -- the destination table.
    (`id`, `tweet`);


-- A table of sentiment score by tweet ID.
CREATE TABLE `tweet_sentiment` (
    `id` BIGINT PRIMARY KEY,

    -- These fields are outputted by the sentiment analyzer. "compound" ranges
    -- from -1 to 1 and generally represents sentiment on a scale of "bad" to
    -- "good". The other three numbers each range from 0 to 1 and together give
    -- a more precise picture of the detected sentiment.
    `compound` FLOAT,
    `positive` FLOAT,
    `negative` FLOAT,
    `neutral` FLOAT
);


-- A MemSQL Pipeline with a transform
CREATE PIPELINE `twitter_sentiment_pipeline` AS
    LOAD DATA KAFKA "public-kafka.memcompute.com:9092/tweets-json"

    -- Here, we specify an executable that will transform each record that
    -- passes through the Pipeline. In this case, our transform function takes
    -- JSON blobs from Twitter and performs a sentiment analysis on the tweet
    -- text, returning a tweet ID and a score.
    WITH TRANSFORM (
        "http://download.memsql.com/pipelines-demo-5.5.0-beta2/transform.tar.gz",
        "transform/transform.py", "")

    -- The transform can also be in the MemSQL master node's filesystem.
    --  WITH TRANSFORM (
        --  "file:///pipelines-example/transform.tar.gz",
	--  "transform/transform.py", "")

    REPLACE INTO TABLE `tweet_sentiment`
    FIELDS TERMINATED BY "\t"
    (`id`, `compound`, `positive`, `negative`, `neutral`);


-- We make sure that our pipelines do not start reading the Kafka topic from the
-- beginning; instead, they starts reading new data as it comes in.
ALTER PIPELINE `twitter_pipeline` SET OFFSETS LATEST;
ALTER PIPELINE `twitter_sentiment_pipeline` SET OFFSETS LATEST;

START PIPELINE `twitter_pipeline`;
START PIPELINE `twitter_sentiment_pipeline`;
