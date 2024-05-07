#!/bin/bash

# cleanup leaked instances
echo "Checking and cleaning up the leaked instances (if any)"
INSTANCE_IDS="$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:sandbox-asg,Values=true" --query 'Reservations[].Instances[?!(Tags[?Key==`aws:autoscaling:groupName`] || Tags[?Key==`SandboxID`])].InstanceId[]')"

while IFS= read -r instance_id; do
    echo "Processing instance ID: $instance_id"
    aws ec2 terminate-instances --instance-ids "$instance_id"
done < <(echo "$INSTANCE_IDS" | jq -r '.[]')