#!/bin/bash

# : ${ASG_NAME:=test-windows-provision}
# : ${AVAILABILITY_ZONE:=us-east-2a}
# : ${EC2_SSH_KEY_FILE:=/run/sandbox/fs/secrets/shared/sandbox-shared.pem}

set -e

source ./common.sh
# redirect stdout to stderr to ensure the stdout output is the desired JSON object.
redirect_stdout

validate_asg $ASG_NAME
validate_az $AVAILABILITY_ZONE
validate_ssh_key $EC2_SSH_KEY_FILE

VOLUME_ID="$(get_volume_id)"

# TODO: need to lock and prevent race condition
INSTANCE_ID="$(claim_instance_from_asg)"

INSTANCE="$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[0].Instances[0]' | jq '.')"

PASSWORD="$(retrieve_password $INSTANCE_ID $EC2_SSH_KEY_FILE)"
PUBLIC_DNS="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicDnsName)"
PUBLIC_IP="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicIp)"

attach_volume_if_needed $VOLUME_ID $INSTANCE_ID

# restore the original terminal settings
restore_stdout

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
