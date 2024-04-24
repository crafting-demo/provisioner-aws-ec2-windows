#!/bin/bash

function usage() {
    cat <<"EOF"
check-ec2-orphan.sh <ORG> <AMI-ID> 
EOF
    exit 2
}

if [ $# -eq 0 ] || [ $# -eq 1 ]; then
    usage
fi

org=$1
ami=$2

instances=$(aws ec2 describe-instances --filters "Name=image-id,Values=$ami" "Name=instance-state-name,Values=running"  --query "Reservations[*].Instances[*].{InstanceId:InstanceId, SandboxID:Tags[?Key=='SandboxID'].Value | [0], Sandbox:Tags[?Key=='Sandbox'].Value | [0]}")
flattened_json=$(echo "$instances" | jq -s 'flatten | .[]' | jq -s ".")

echo "$flattened_json" | jq -c ".[]" | while IFS= read -r instance_json; do
    instance_id=$(echo "$instance_json" | jq -r '.InstanceId')
    sandbox_id=$(echo "$instance_json" | jq -r '.SandboxID')

    echo "processing instance of ID: $instance_id, the associated sandbox ID is $sandbox_id"
    csops -T prod sandbox status --sandbox $sandbox_id --org $org > /dev/null
    if ! [ $? -eq 0 ]; then
        echo "EC2 instance of ID: $instance_id is an orphan."
    fi
done