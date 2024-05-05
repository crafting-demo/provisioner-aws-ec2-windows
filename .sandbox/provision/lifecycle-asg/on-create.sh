#!/bin/bash

# : ${ASG_NAME:=test-windows-provision}
# : ${AVAILABILITY_ZONE:=us-east-2a}
# : ${EC2_SSH_KEY_FILE:=/run/sandbox/fs/secrets/shared/sandbox-shared.pem}
: ${VOLUME_SIZE:=10}
: ${MAX_RETRIES:=10}

set -e

source ./common.sh
# redirect stdout to stderr to ensure the stdout output is the desired JSON object.
redirect_stdout

validate_asg $ASG_NAME
validate_az $AVAILABILITY_ZONE
validate_ssh_key $EC2_SSH_KEY_FILE

INSTANCE_ID="$(claim_instance_from_asg)"
echo "$INSTANCE_ID"
INSTANCE="$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[0].Instances[0]' | jq '.')"
PASSWORD="$(retrieve_password $INSTANCE_ID $EC2_SSH_KEY_FILE)"   
PUBLIC_DNS="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicDnsName)"
PUBLIC_IP="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicIp)"

volume_info="$(aws ec2 describe-volumes --filters Name=tag:SandboxID,Values=$SANDBOX_ID)"
VOLUME_ID=volume_id
[[ $(jq '.Volumes | length' <<< "$volume_info") -gt 0 ]] || {
    volume="$(aws ec2 create-volume --size $VOLUME_SIZE --availability-zone $AVAILABILITY_ZONE --tag-specification "ResourceType=volume,Tags=[{Key=SandboxID,Value=$SANDBOX_ID}]")"
    VOLUME_ID=$(echo $volume | jq -r .VolumeId)
}
aws ec2 wait volume-available --volume-ids $VOLUME_ID
aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device "/dev/xvdf"

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


