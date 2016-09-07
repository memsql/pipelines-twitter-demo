CREATE DATABASE `example`;
USE `example`;

CREATE TABLE `tweets` (
    `tweet_text` JSON
);

CREATE PIPELINE `twitter_pipeline`
    AS LOAD DATA KAFKA "ec2-54-210-221-141.compute-1.amazonaws.com:9092/test"
    --  WITH TRANSFORM ("file:///pipelines-example/transform.py", "", "")
    INTO TABLE `tweets`
    --  FIELDS TERMINATED BY "," ENCLOSED BY "\"" ESCAPED BY "\\"
    LINES TERMINATED BY "\n";

ALTER PIPELINE `twitter_pipeline` SET OFFSETS LATEST;

--  SET TRANSFORM TEMPLATE "/usr/bin/python3 %cmd";

START PIPELINE `twitter_pipeline`;
