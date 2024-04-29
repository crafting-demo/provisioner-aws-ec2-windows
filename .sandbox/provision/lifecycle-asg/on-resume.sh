#!/bin/bash

ASG_NAME=test-windows-provision
AVAILABILITY_ZONE=us-east-2a

source ./common.sh

# adjust the terminal output settings 
redirect_output on-resume.log

VOLUME_ID="$(stored_volume_id)"

# TODO: need to lock and prevent race condition
INSTANCE_IDS="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $ASG_NAME --query "AutoScalingGroups[].Instances[].InstanceId" --output text)"
INSTANCE_ID="$(echo $INSTANCE_IDS | awk '{print $1}')"

aws autoscaling detach-instances --instance-ids $INSTANCE_ID --auto-scaling-group-name $ASG_NAME --no-should-decrement-desired-capacity
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Sandbox,Value=$SANDBOX_NAME --tags Key=SandboxID,Value=$SANDBOX_ID
INSTANCE="$(aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[0].Instances[0]' | jq '.')"
PASSWORD="$(aws ec2 get-password-data --instance-id $INSTANCE_ID | jq -r .PasswordData | base64 -d  | openssl pkeyutl  -decrypt -inkey /run/sandbox/fs/secrets/shared/employ-temp.pem)"
PUBLIC_DNS="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicDnsName)"
PUBLIC_IP="$(echo $INSTANCE | jq -r .NetworkInterfaces[0].Association.PublicIp)"

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
