#!/bin/bash

# Runs a psql interactive session

docker run -ti --rm \
  --name wk32_psql \
  --network=container:libraries_postgresql_test_pg \
  --user 1000:1000 \
  -v $(pwd)/../src:$(pwd)/../src \
  --workdir $(pwd)/../src \
  -e "HOST=localhost" \
  -e "PORT=5432" \
  -e "DB=postgres" \
  -e "USER=postgres" \
  -e "PASS=postgres" \
  --entrypoint /bin/bash \
  malkab/postgis:idiosyncratic_ibex \
  -c run_psql.sh
