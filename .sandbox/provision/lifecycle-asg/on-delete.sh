#!/bin/bash

source ./common.sh

redirect_output on-delete.log

INSTANCE_ID="$(stored_instance_id)"
VOLUME_ID="$(stored_volume_id)"

if [ -n "$INSTANCE_ID" ] ; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
fi

if [ -n "$VOLUME_ID" ]; then
    aws ec2 delete-volume --volume-id $VOLUME_ID
fi

restore_output

