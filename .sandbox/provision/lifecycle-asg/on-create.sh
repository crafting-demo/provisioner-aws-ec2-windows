#!/bin/bash

ASG_NAME:=test-windows-provision
AVAILABILITY_ZONE:=us-east-2a
MAX_RETRIES:=3
VOLUME_SIZE:=10
EC2_SSH_KEY_FILE:=/run/sandbox/fs/secrets/shared/sandbox-shared.pem

source ./common.sh

# adjust the terminal output settings 
redirect_output on-create.log

INSTANCE_IDS="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $ASG_NAME --no-paginate --query "AutoScalingGroups[].Instances[].InstanceId" --output text)"
INSTANCE_ID="$(echo $INSTANCE_IDS | awk '{print $1}')"

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Sandbox,Value=$SANDBOX_NAME --tags Key=SandboxID,Value=$SANDBOX_ID
aws autoscaling detach-instances --instance-ids $INSTANCE_ID --auto-scaling-group-name $ASG_NAME --no-should-decrement-desired-capacity

INSTANCE="$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[0].Instances[0]' | jq '.')"
PASSWORD_DATA="$(aws ec2 get-password-data --instance-id $INSTANCE_ID)"

retry_count=0
while [[ $retry_count -lt $MAX_RETRIES ]]; do
    PASSWORD_DATA="$(aws ec2 get-password-data --instance-id $INSTANCE_ID | jq -r .PasswordData)"
    [[ -z "$PASSWORD_DATA" ]] || break
    retry_count=$((retry_count + 1))
    sleep 10
done

PASSWORD="$(echo $PASSWORD_DATA  | base64 -d | openssl pkeyutl -decrypt -inkey $EC2_SSH_KEY_FILE)"
PUBLIC_DNS="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicDnsName)"
PUBLIC_IP="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicIp)"

volume_info="${aws ec2 describe-volume --filters "Name=tag:SandboxID,Values=$SANDBOX_ID"}"
VOLUME_ID="$(jq -r '.Volumes[0].VolumeId' <<< $volume_info)"
if [[ $(jq '.Volumes | length' <<< "$volume_info") -gt 0 ]]; then
    volume="$(aws ec2 create-volume --size $VOLUME_SIZE --availability-zone $AVAILABILITY_ZONE --tag-specification "ResourceType=volume,Tags=[{Key=SandboxID,Value=$SANDBOX_ID}]")"
    VOLUME_ID=$(echo $volume | jq -r .VolumeId)
fi
aws ec2 wait volume-available --volume-ids $VOLUME_ID
aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device "/dev/xvdf"

# restore the original terminal settings
restore_output

cat <<EOF > .windows-state.json
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

cat .windows-state.json


