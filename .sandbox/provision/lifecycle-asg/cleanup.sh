#!/bin/bash

source ./common.sh

# cleanup leaked instances
echo "Checking and cleaning up the leaked instances (if any)"
INSTANCE_IDS="$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:$SANDBOX_ASG_TAG,Values=true" --query "Reservations[].Instances[?!(Tags[?Key=='aws:autoscaling:groupName'] || Tags[?Key==$SANBODX_ID_TAG])].InstanceId[]" | jq -cMr '.[]')" 
[[ -z $INSTANCE_IDS ]] || aws ec2 terminate-instances --instance-ids "${INSTANCE_IDS[@]}"
