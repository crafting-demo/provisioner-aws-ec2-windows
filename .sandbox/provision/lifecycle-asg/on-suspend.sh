#!/bin/bash

set -ex

source ./common.sh

function on_suspend() {
    INSTANCE_ID="$(get_instance_id)"
    VOLUME_ID="$(get_volume_id)"
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

    # we need to wait for termination's completed, in case of some race conditions: suspend and resume the sandbox immedidately.
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
}

on_suspend >&2
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "volume_id": "$VOLUME_ID",
    "instance": ""
}
EOF