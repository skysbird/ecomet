#!/bin/sh
# NOTE: mustache templates need \ because they are not awesome.
exec erl -pa ebin deps/*/ebin \
    -boot start_sasl \
    -name "ecomet_server1@127.0.0.1" \
    -s lager \
    -s ecomet_thrift_server \
    -setcookie abc \
    -config ../ecomet.config\
    -K true \
    -P 134217727
