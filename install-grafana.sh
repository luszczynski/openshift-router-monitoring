#!/bin/bash

if [ $# != 1 ]; then
    echo "Usage: $0 <namespace>"
    exit 0
fi

oc new-app grafana/grafana:5.3.4 -n $1

oc expose svc/grafana -n $1

read -n1 -r -p  "Wait for Grafana to start running. Open another terminal window and run the 'oc get pods -w' command. When you confirm that the Grafana pod is running, press any key to continue..." key

protocol="http://"
payload="$( mktemp )"
cat <<EOF >"${payload}"
{
"name": "Prometheus",
"type": "prometheus",
"access": "Browser",
"url": "https://$( oc get route prometheus -n $1 -o jsonpath='{.spec.host}' )",
"basicAuth": false,
"withCredentials": false
}
EOF

# Set up a Prometheus datasource in Grafana
grafana_host="${protocol}$( oc -n $1 get route grafana -o jsonpath='{.spec.host}' )"
dashboard_file="./grafana-dashboard.json"
curl --insecure -H "Content-Type: application/json" -u admin:admin "${grafana_host}/api/datasources" -X POST -d "@${payload}"
