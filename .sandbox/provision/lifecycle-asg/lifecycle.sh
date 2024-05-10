#!/bin/bash

source ./common.sh

function provision() {
    validate_asg "$ASG_NAME"
    validate_az "$AVAILABILITY_ZONE"
    validate_ssh_key "$EC2_SSH_KEY_FILE"

    INSTANCE_ID="$(claim_instance_from_asg)"
    INSTANCE="$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" --query 'Reservations[0].Instances[0]')"

    PASSWORD="$(retrieve_password "$INSTANCE_ID" "$EC2_SSH_KEY_FILE")"
    PUBLIC_DNS="$(echo "$INSTANCE" | jq -cMr '.NetworkInterfaces[0].Association.PublicDnsName')"
    PUBLIC_IP="$(echo "$INSTANCE" | jq -cMr '.NetworkInterfaces[0].Association.PublicIp')"

    VOLUME_ID="$(create_volume_if_needed)"
    attach_volume_if_needed "$VOLUME_ID" "$INSTANCE_ID"
}

function suspend() {
   terminate_instance
}

function delete() {
    terminate_instance
    delete_volume
    cleanup
}

set -ex
cmd="$1"
case "$cmd" in 
    create|resume)
        provision >&2
        ;;
    suspend)
        suspend >&2
        ;;
    delete)
        delete >&2
        ;;
    *) fatal "Unknown command"
esac
cat <<EOF 
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "password": "$PASSWORD",
    "public_dns": "$PUBLIC_DNS",
    "public_ip": "$PUBLIC_IP",
    "volume_id": "$VOLUME_ID",
    "instance": "$INSTANCE_ID"
}
EOF