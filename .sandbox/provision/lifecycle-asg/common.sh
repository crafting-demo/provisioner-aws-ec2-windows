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
    jq -r .volume_id .windows-state.json
}

function stored_instance_id() {
    if [ ! -e ".windows-state.json" ]; then
        echo "Can not restore the instance ID as the state file does not exist"
        exit 1
    fi

    jq -r .instance .windows-state.json
}

# retrieve_password INSTANCE_ID KEY_FILE
function retrieve_password() {
    ${MAX_RETRIES:=10}
    instance_id=$1
    ec2_ssh_key_file=$2

    PASSWORD_DATA="$(aws ec2 get-password-data --instance-id $instance_id)"

    retry_count=0
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        password_data="$(aws ec2 get-password-data --instance-id $instance_id | jq -r .PasswordData)"
        [[ -z "$password_data" ]] || break
        retry_count=$((retry_count + 1))
        sleep 10
    done

    return "$(aws ec2 get-password-data --instance-id $instance_id | jq -r .PasswordData | base64 -d  | openssl pkeyutl  -decrypt -inkey $ec2_ssh_key_file)"
}