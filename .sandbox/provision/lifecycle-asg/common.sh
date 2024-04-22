#!/bin/bash

function redirect_output() {
    local dest="$1"
    exec 3>&1 4>&2
    exec &> $dest
    set -ex
}

function restore_output() {
    set +x
    exec >&3 2>&4
    exec 3>&- 4>&-
}

function stored_volume_id() {
    if [ ! -e ".windows-state.json" ]; then
        echo "Can not restore the volume ID as the state file does not exist"
        exit 1
    fi
    echo $(jq -r .volume_id .windows-state.json)
}

function stored_instance_id() {
    if [ ! -e ".windows-state.json" ]; then
        echo "Can not restore the instance ID as the state file does not exist"
        exit 1
    fi

    echo $(jq -r .instance .windows-state.json)
}