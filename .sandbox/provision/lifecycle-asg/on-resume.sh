#!/bin/bash

set -ex

source ./common.sh

function on_resume() {
    validate_asg "$ASG_NAME"
    validate_az "$AVAILABILITY_ZONE"
    validate_ssh_key "$EC2_SSH_KEY_FILE"

    VOLUME_ID="$(get_volume_id)"

    # TODO: need to lock and prevent race condition
    INSTANCE_ID="$(claim_instance_from_asg)"
    INSTANCE="$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" --query 'Reservations[0].Instances[0]')"

    PASSWORD="$(retrieve_password "$INSTANCE_ID" "$EC2_SSH_KEY_FILE")"
    PUBLIC_DNS="$(echo "$INSTANCE" | jq -cMr .NetworkInterfaces[0].Association.PublicDnsName)"
    PUBLIC_IP="$(echo "$INSTANCE" | jq -cMr .NetworkInterfaces[0].Association.PublicIp)"

    attach_volume_if_needed "$VOLUME_ID" "$INSTANCE_ID"
}

on_resume >&2
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
