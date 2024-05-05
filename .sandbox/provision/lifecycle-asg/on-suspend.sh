#!/bin/bash

set -e

source ./common.sh
# redirect stdout to stderr to ensure the stdout output is the desired JSON object.
redirect_stdout

INSTANCE_ID="$(get_instance_id)"
VOLUME_ID="$(get_volume_id)"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

restore_stdout

cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "volume_id": "$VOLUME_ID",
    "instance": ""
}
EOF