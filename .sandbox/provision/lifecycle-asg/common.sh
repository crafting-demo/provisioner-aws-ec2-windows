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
    : ${MAX_RETRIES:=10}
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

    echo "$(aws ec2 get-password-data --instance-id $instance_id | jq -r .PasswordData | base64 -d  | openssl pkeyutl  -decrypt -inkey $ec2_ssh_key_file)"
}

# validate_asg ASG_NAME
function validate_asg() {
    auto_scaling_group_name=$1

    result=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $auto_scaling_group_name)
    [[ $(jq '.AutoScalingGroups | length' <<< "$result") -gt 0 ]] || {
        echo "Invalid auto scaling group: $auto_scaling_group_name"
        exit 1
    }
}

# validate_az AZ
function validate_az() {
    availability_zone=$1

    _=$(aws ec2 describe-availability-zones --zone-name $availability_zone)

    [[ $? -eq 0 ]] || {
        echo "Invalid availablity zone: $availability_zone"
        exit 1
    }
}

# validate_ssh_key PATH
function validate_ssh_key() {
    ssh_key_path=$1

    [[ -f $ssh_key_path ]] || {
        echo "Invalid SSH key path: $ssh_key_path"
        exit 1
    }
}

