#!/bin/bash

mkdir -p "/home/vitess/vtdataroot/tmp"

echo '{"vtctlds":[{"host":{"fqdn":"vtctl:15000","hostname":"vtctl:15999"}}],"vtgates":[{"host":{"hostname":"vtgate:15991"}}]}' \
  > '/home/vitess/vitess/vtadmin/discovery.json'

# Start vtadmin
vtadmin \
  --addr ":14200" \
  --http-origin "http://localhost:14201" \
  --http-tablet-url-tmpl "http://{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  --tracer "opentracing-jaeger" \
  --grpc-tracing \
  --http-tracing \
  --logtostderr \
  --alsologtostderr \
  --rbac \
  --rbac-config="/home/vitess/vitess/vtadmin/rbac.yaml" \
  --cluster "id=local,name=local,discovery=staticfile,discovery-staticfile-path=/home/vitess/vitess/vtadmin/discovery.json,tablet-fqdn-tmpl={{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}" \
  > "/home/vitess/vtdataroot/tmp/vtadmin-api.out" 2>&1 &

sleep 3

echo $! > "/home/vitess/vtdataroot/tmp/vtadmin-api.pid"

# Install web resources
npm --prefix "/home/web/vtadmin" --silent install

REACT_APP_VTADMIN_API_ADDRESS="http://localhost:14200" \
  REACT_APP_ENABLE_EXPERIMENTAL_TABLET_DEBUG_VARS="true" \
  npm run --prefix "/home/web/vtadmin" build

# Start web server
/home/web/vtadmin/node_modules/.bin/serve --no-clipboard -l "14201" -s "/home/web/vtadmin/build" \
  > "/home/vitess/vtdataroot/tmp/vtadmin-web.out" 2>&1 &

sleep 3

echo $! > "/home/vitess/vtdataroot/tmp/vtadmin-web.pid"

disown -a
