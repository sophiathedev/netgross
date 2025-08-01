#!/bin/bash
set -e
bundle check || bundle install

until pg_isready -h db -p 5432 -U postgres; do
  echo "Waiting for postgres..."
  sleep 1
done

# Enable jemalloc for reduced memory usage and latency.
if [ -z "${LD_PRELOAD+x}" ]; then
    LD_PRELOAD=$(find /usr/lib -name libjemalloc.so.2 -print -quit)
    export LD_PRELOAD
fi

bundle exec rails db:prepare
bundle exec rails db:migrate

exec ./bin/thrust ./bin/rails server -b '0.0.0.0' -p 3000
