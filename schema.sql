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
    team_location AS CASE
        WHEN (text LIKE '%hawks%') THEN 'Atlanta'
        WHEN (text LIKE '%celtics%') THEN 'Boston'
        WHEN (text LIKE '%nets%') THEN 'Brooklyn'
        WHEN (text LIKE '%hornets%') THEN 'Charlotte'
        WHEN (text LIKE '%bulls%') THEN 'Chicago'
        WHEN (text LIKE '%cavaliers%') THEN 'Cleveland'
        WHEN (text LIKE '%mavericks%') THEN 'Dallas'
        WHEN (text LIKE '%nuggets%') THEN 'Denver'
        WHEN (text LIKE '%pistons%') THEN 'Detroit'
        WHEN (text LIKE '%warriors%') THEN 'Golden State'
        WHEN (text LIKE '%rockets%') THEN 'Houston'
        WHEN (text LIKE '%pacers%') THEN 'Indiana'
        WHEN (text LIKE '%clippers%') THEN 'Los Angeles'
        WHEN (text LIKE '%lakers%') THEN 'Los Angeles'
        WHEN (text LIKE '%grizzlies%') THEN 'Memphis'
        WHEN (text LIKE '%heat%') THEN 'Miami'
        WHEN (text LIKE '%bucks%') THEN 'Milwaukee'
        WHEN (text LIKE '%timberwolves%') THEN 'Minnesota'
        WHEN (text LIKE '%pelicans%') THEN 'New Orleans'
        WHEN (text LIKE '%knicks%') THEN 'New York'
        WHEN (text LIKE '%thunder%') THEN 'Oklahoma City'
        WHEN (text LIKE '%magic%') THEN 'Orlando'
        WHEN (text LIKE '%sixers%') THEN 'Philadelphia'
        WHEN (text LIKE '%suns%') THEN 'Phoenix'
        WHEN (text LIKE '%blazers%') THEN 'Portland'
        WHEN (text LIKE '%kings%') THEN 'Sacramento'
        WHEN (text LIKE '%spurs%') THEN 'San Antonio'
        WHEN (text LIKE '%raptors%') THEN 'Toronto'
        WHEN (text LIKE '%jazz%') THEN 'Utah'
        WHEN (text LIKE '%wizards%') THEN 'Washington' 
        ELSE 'Unknown' END PERSISTED TEXT,
    team AS CASE
        WHEN (text LIKE '%hawks%') THEN 'Hawks'
        WHEN (text LIKE '%celtics%') THEN 'Celtics'
        WHEN (text LIKE '%nets%') THEN 'Nets'
        WHEN (text LIKE '%hornets%') THEN 'Hornets'
        WHEN (text LIKE '%bulls%') THEN 'Bulls'
        WHEN (text LIKE '%cavaliers%') THEN 'Cavaliers'
        WHEN (text LIKE '%mavericks%') THEN 'Mavericks'
        WHEN (text LIKE '%nuggets%') THEN 'Nuggets'
        WHEN (text LIKE '%pistons%') THEN 'Pistons'
        WHEN (text LIKE '%warriors%') THEN 'Warriors'
        WHEN (text LIKE '%rockets%') THEN 'Rockets'
        WHEN (text LIKE '%pacers%') THEN 'Pacers'
        WHEN (text LIKE '%clippers%') THEN 'Clippers'
        WHEN (text LIKE '%lakers%') THEN 'Lakers'
        WHEN (text LIKE '%grizzlies%') THEN 'Grizzlies'
        WHEN (text LIKE '%heat%') THEN 'Heat'
        WHEN (text LIKE '%bucks%') THEN 'Bucks'
        WHEN (text LIKE '%timberwolves%') THEN 'Timberwolves'
        WHEN (text LIKE '%pelicans%') THEN 'Pelicans'
        WHEN (text LIKE '%knicks%') THEN 'Knicks'
        WHEN (text LIKE '%thunder%') THEN 'Thunder'
        WHEN (text LIKE '%magic%') THEN 'Magic'
        WHEN (text LIKE '%sixers%') THEN 'Sixers'
        WHEN (text LIKE '%suns%') THEN 'Suns'
        WHEN (text LIKE '%blazers%') THEN 'Blazers'
        WHEN (text LIKE '%kings%') THEN 'Kings'
        WHEN (text LIKE '%spurs%') THEN 'Spurs'
        WHEN (text LIKE '%raptors%') THEN 'Raptors'
        WHEN (text LIKE '%jazz%') THEN 'Jazz'
        WHEN (text LIKE '%wizards%') THEN 'Wizards' 
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
    t.ts, t.team, ts.compound,
    ts.positive, ts.negative, ts.neutral
FROM
    tweets AS t
    INNER JOIN tweet_sentiment AS ts
    ON t.id = ts.id;


CREATE VIEW tweets_per_team as
SELECT
    FORMAT(COUNT(*), 0) tweet_scores, team
FROM tweet_scores t
GROUP BY team;


CREATE VIEW tweets_per_sentiment_per_team_timeseries AS
SELECT
    FROM_UNIXTIME(TRUNCATE(UNIX_TIMESTAMP(ts) / 60, 0) * 60) AS ts_bucket,
    TRUNCATE(compound, 1) AS sentiment_bucket,
    FORMAT(COUNT(*), 0) AS tweet_volume,
    team
FROM tweet_scores t
GROUP BY ts_bucket, sentiment_bucket, team;


CREATE VIEW sentiment_histogram AS
SELECT
    sentiment_bucket,
    SUM(IF(team = 'Hawks', tweet_volume, 0)) as hawks_tweets,
    SUM(IF(team = 'Celtics', tweet_volume, 0)) as celtics_tweets,
    SUM(IF(team = 'Nets', tweet_volume, 0)) as nets_tweets,
    SUM(IF(team = 'Hornets', tweet_volume, 0)) as hornets_tweets,
    SUM(IF(team = 'Bulls', tweet_volume, 0)) as bulls_tweets,
    SUM(IF(team = 'Cavaliers', tweet_volume, 0)) as cavaliers_tweets,
    SUM(IF(team = 'Mavericks', tweet_volume, 0)) as mavericks_tweets,
    SUM(IF(team = 'Nuggets', tweet_volume, 0)) as nuggets_tweets,
    SUM(IF(team = 'Pistons', tweet_volume, 0)) as pistons_tweets,
    SUM(IF(team = 'Warriors', tweet_volume, 0)) as warriors_tweets,
    SUM(IF(team = 'Rockets', tweet_volume, 0)) as rockets_tweets,
    SUM(IF(team = 'Pacers', tweet_volume, 0)) as pacers_tweets,
    SUM(IF(team = 'Clippers', tweet_volume, 0)) as clippers_tweets,
    SUM(IF(team = 'Lakers', tweet_volume, 0)) as lakers_tweets,
    SUM(IF(team = 'Grizzlies', tweet_volume, 0)) as grizzlies_tweets,
    SUM(IF(team = 'Heat', tweet_volume, 0)) as heat_tweets,
    SUM(IF(team = 'Bucks', tweet_volume, 0)) as bucks_tweets,
    SUM(IF(team = 'Timberwolves', tweet_volume, 0)) as timberwolves_tweets,
    SUM(IF(team = 'Pelicans', tweet_volume, 0)) as pelicans_tweets,
    SUM(IF(team = 'Knicks', tweet_volume, 0)) as knicks_tweets,
    SUM(IF(team = 'Thunder', tweet_volume, 0)) as thunder_tweets,
    SUM(IF(team = 'Magic', tweet_volume, 0)) as magic_tweets,
    SUM(IF(team = 'Sixers', tweet_volume, 0)) as sixers_tweets,
    SUM(IF(team = 'Suns', tweet_volume, 0)) as suns_tweets,
    SUM(IF(team = 'Blazers', tweet_volume, 0)) as blazers_tweets,
    SUM(IF(team = 'Kings', tweet_volume, 0)) as kings_tweets,
    SUM(IF(team = 'Spurs', tweet_volume, 0)) as spurs_tweets,
    SUM(IF(team = 'Raptors', tweet_volume, 0)) as raptors_tweets,
    SUM(IF(team = 'Jazz', tweet_volume, 0)) as jazz_tweets,
    SUM(IF(team = 'Wizards', tweet_volume, 0)) as wizards_tweets 
FROM tweets_per_sentiment_per_team_timeseries t
GROUP BY sentiment_bucket
ORDER BY sentiment_bucket;


CREATE VIEW timeseries_histogram AS
SELECT
    ts_bucket,
    SUM(IF(team = 'Hawks', tweet_volume, 0)) as hawks_tweets,
    SUM(IF(team = 'Celtics', tweet_volume, 0)) as celtics_tweets,
    SUM(IF(team = 'Nets', tweet_volume, 0)) as nets_tweets,
    SUM(IF(team = 'Hornets', tweet_volume, 0)) as hornets_tweets,
    SUM(IF(team = 'Bulls', tweet_volume, 0)) as bulls_tweets,
    SUM(IF(team = 'Cavaliers', tweet_volume, 0)) as cavaliers_tweets,
    SUM(IF(team = 'Mavericks', tweet_volume, 0)) as mavericks_tweets,
    SUM(IF(team = 'Nuggets', tweet_volume, 0)) as nuggets_tweets,
    SUM(IF(team = 'Pistons', tweet_volume, 0)) as pistons_tweets,
    SUM(IF(team = 'Warriors', tweet_volume, 0)) as warriors_tweets,
    SUM(IF(team = 'Rockets', tweet_volume, 0)) as rockets_tweets,
    SUM(IF(team = 'Pacers', tweet_volume, 0)) as pacers_tweets,
    SUM(IF(team = 'Clippers', tweet_volume, 0)) as clippers_tweets,
    SUM(IF(team = 'Lakers', tweet_volume, 0)) as lakers_tweets,
    SUM(IF(team = 'Grizzlies', tweet_volume, 0)) as grizzlies_tweets,
    SUM(IF(team = 'Heat', tweet_volume, 0)) as heat_tweets,
    SUM(IF(team = 'Bucks', tweet_volume, 0)) as bucks_tweets,
    SUM(IF(team = 'Timberwolves', tweet_volume, 0)) as timberwolves_tweets,
    SUM(IF(team = 'Pelicans', tweet_volume, 0)) as pelicans_tweets,
    SUM(IF(team = 'Knicks', tweet_volume, 0)) as knicks_tweets,
    SUM(IF(team = 'Thunder', tweet_volume, 0)) as thunder_tweets,
    SUM(IF(team = 'Magic', tweet_volume, 0)) as magic_tweets,
    SUM(IF(team = 'Sixers', tweet_volume, 0)) as sixers_tweets,
    SUM(IF(team = 'Suns', tweet_volume, 0)) as suns_tweets,
    SUM(IF(team = 'Blazers', tweet_volume, 0)) as blazers_tweets,
    SUM(IF(team = 'Kings', tweet_volume, 0)) as kings_tweets,
    SUM(IF(team = 'Spurs', tweet_volume, 0)) as spurs_tweets,
    SUM(IF(team = 'Raptors', tweet_volume, 0)) as raptors_tweets,
    SUM(IF(team = 'Jazz', tweet_volume, 0)) as jazz_tweets,
    SUM(IF(team = 'Wizards', tweet_volume, 0)) as wizards_tweets 
FROM tweets_per_sentiment_per_team_timeseries t
GROUP BY ts_bucket
ORDER BY ts_bucket;


-- We make sure that our pipelines do not start reading the Kafka topic from the
-- beginning; instead, they starts reading new data as it comes in.
ALTER PIPELINE twitter_pipeline SET OFFSETS LATEST;
ALTER PIPELINE twitter_sentiment_pipeline SET OFFSETS LATEST;

START PIPELINE twitter_pipeline;
START PIPELINE twitter_sentiment_pipeline;
