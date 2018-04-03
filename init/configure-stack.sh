#!/bin/bash
until curl -u elastic:${ES_PASSWORD} -s http://elasticsearch:9200/_cat/health -o /dev/null; do
    echo Waiting for Elasticsearch...
    sleep 1
done

until curl -s http://kibana:5601/login -o /dev/null; do
    echo Waiting for Kibana...
    sleep 1
done

curl -s -XPUT http://elastic:${ES_PASSWORD}@elasticsearch:9200/.kibana/config/${ELASTIC_VERSION} \
     -d "{\"defaultIndex\" : \"${DEFAULT_INDEX_PATTERN}\"}"

PIPELINES=/usr/local/bin/pipelines/*.json
for f in $PIPELINES
do
     filename=$(basename $f)
     pipeline_id="${filename%.*}"
     echo "Loading $pipeline_id ingest chain..."
     curl -s  -H 'Content-Type: application/json' -XPUT http://elastic:${ES_PASSWORD}@elasticsearch:9200/_ingest/pipeline/$pipeline_id -d@$f
done

TEMPLATES=/usr/local/bin/templates/*.json
for f in $TEMPLATES
do
     filename=$(basename $f)
     template_id="${filename%.*}"
     echo "Loading $template_id template..."
     curl -s  -H 'Content-Type: application/json' -XPUT http://elastic:${ES_PASSWORD}@elasticsearch:9200/_template/$template_id -d@$f
     curl -s -XPUT http://elastic:${ES_PASSWORD}@elasticsearch:9200/.kibana/index-pattern/$template_id-* \
     -d "{\"title\" : \"$template_id-*\",  \"timeFieldName\": \"@timestamp\"}"
done
