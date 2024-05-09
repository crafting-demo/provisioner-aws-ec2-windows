#!/bin/bash

: ${VOLUME_SIZE:=10}
: ${MAX_RETRIES:=10}

set -ex

source ./common.sh

function on_create() {
    validate_asg "$ASG_NAME"
    validate_az "$AVAILABILITY_ZONE"
    validate_ssh_key "$EC2_SSH_KEY_FILE"

    INSTANCE_ID="$(claim_instance_from_asg)"
    INSTANCE="$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" --query 'Reservations[0].Instances[0]')"

    PASSWORD="$(retrieve_password "$INSTANCE_ID" "$EC2_SSH_KEY_FILE")"
    PUBLIC_DNS="$(echo "$INSTANCE" | jq -cMr .NetworkInterfaces[0].Association.PublicDnsName)"
    PUBLIC_IP="$(echo "$INSTANCE" | jq -cMr .NetworkInterfaces[0].Association.PublicIp)"

    volume_info="$(aws ec2 describe-volumes --filters Name=tag:SandboxID,Values="$SANDBOX_ID")"
    VOLUME_ID=""
    [[ $(jq -cMr '.Volumes | length' <<< "$volume_info") -gt 0 ]] || {
        volume="$(aws ec2 create-volume --size "$VOLUME_SIZE" --availability-zone "$AVAILABILITY_ZONE" --tag-specification "ResourceType=volume,Tags=[{Key=SandboxID,Value="$SANDBOX_ID"}]")"
        VOLUME_ID=$(echo "$volume" | jq -cMr .VolumeId)
    }

    attach_volume_if_needed "$VOLUME_ID" "$INSTANCE_ID"
}

on_create >&2
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


