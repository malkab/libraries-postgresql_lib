#!/bin/bash

# -----------------------------------------------------------------
#
# Runs a standalone database server.
#
# -----------------------------------------------------------------
docker run -ti --rm \
  --name libraries_postgresql_test_pg \
  --hostname xxlibraries_postgresql_test_pg \
  -p 5432:5432 \
  -e LOCALE=es_ES \
  malkab/postgis:idiosyncratic_ibex
