#!/usr/bin/env bash

set -e -u

# Start Elasticsearch and wait for it to respond.
/tmp/elasticsearch-2.4.5/bin/elasticsearch -Des.insecure.allow.root=true -d
wait-for-it 127.0.0.1:9200

# Start rsyslogd
rsyslogd -v
printf "\n\nrsyslog.conf:\n\n"
cat /tmp/rsyslog.conf
rsyslogd -f /tmp/rsyslog.conf -i /tmp/rsyslogd.pid

printf "\n\nrsyslogd memory use:\n"
ps up $(pgrep -f rsyslogd)

# Send messages to rsyslogd
test_message=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c 10000)
for i in {1..5}; do
  printf "\n\n== Generating log data ($i) ==\n"
  for j in {1..10000}; do logger --tcp --server 127.0.0.1 --port 9999 --priority local0.info --tag "test[$i-$j]" "$test_message"; done

  # Print indexing progress.
  printf "\nElasticsearch count:\n"
  curl -s "http://127.0.0.1:9200/_cat/count?v"

  # Print memory usage.
  printf "\nrsyslogd memory use:\n"
  ps up $(pgrep -f rsyslogd)
done
