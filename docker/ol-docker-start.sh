#!/bin/bash

# quick method to start all ol services from one script
# inside an container, bypass all upstart/services

CONFIG=conf/openlibrary-docker.yml

reindex-solr() {
  server=$1
  config=$2
  for thing in books authors; do
    psql openlibrary -t -c 'select key from thing' | sed 's/ *//' | grep "^/$thing/" \
      | PYTHONPATH=$PWD xargs python openlibrary/solr/update_work.py -s $server -c $config --data-provider=legacy
  done
}

echo "Starting ol services."

# TODO: why does nginx appear not necessary?
#echo "Starting nginx"
#service nginx restart

# postgres
su postgres -c "/etc/init.d/postgresql start"

# memcached
service memcached start

# infobase
su openlibrary -c "scripts/infobase-server conf/infobase.yml 7000" &

# wait unit postgres is ready, then reindex solr
export -f reindex-solr
su openlibrary -c "until pg_isready; do sleep 5; done && reindex-solr localhost $CONFIG" &

# solr updater
su openlibrary -c "python scripts/new-solr-updater.py \
  -c $CONFIG \
  --state-file solr-update.offset \
  --ol-url http://web/" &

# ol server, running in the foreground to avoid exiting container
su openlibrary -c "authbind --deep scripts/openlibrary-server $CONFIG --gunicorn -w4 -t180 -b:80"

