#!/bin/bash

function resource_output() {
    jq -cMr ".$1.value" </run/sandbox/fs/resources/windows/state 2>/dev/null || true
}

function wait_for_resource() {
    while true ; do
        [[ -z "$(resource_output public_dns)" ]] || return 0
        sleep 1
    done
}

set -ex

echo "Waiting for guacamole-jetty"
cs wait service guacamole
echo "Waiting for resource: windows"
wait_for_resource

# call config server to create/update the Windows credentials.
curl -X PUT http://guacamole:8081/params --data-urlencode "hostname=$(resource_output public_dns)" --data-urlencode "username=Administrator" --data-urlencode "password=$(resource_output password)"
sleep infinity

