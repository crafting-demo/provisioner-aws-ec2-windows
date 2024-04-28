#!/bin/bash

source ./common.sh

# adjust the terminal output settings 
redirect_output on-suspend.log
INSTANCE_ID="$(stored_instance_id)"
VOLUME_ID="$(stored_volume_id)"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

restore_output

cat <<EOF > .windows-state.json
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "volume_id": "$VOLUME_ID",
    "instance": ""
}
EOF

cat .windows-state.json