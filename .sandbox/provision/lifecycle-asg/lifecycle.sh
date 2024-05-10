#!/bin/bash

source ./common.sh

function provision() {
    validate_asg "$ASG_NAME"
    validate_az "$AVAILABILITY_ZONE"
    validate_ssh_key "$EC2_SSH_KEY_FILE"

    INSTANCE_ID="$(claim_instance_from_asg)"
    INSTANCE="$(aws ec2 describe-instances --instance-id "$INSTANCE_ID" --query 'Reservations[0].Instances[0]')"

    PASSWORD="$(retrieve_password "$INSTANCE_ID" "$EC2_SSH_KEY_FILE")"
    PUBLIC_DNS="$(echo "$INSTANCE" | jq -cMr '.NetworkInterfaces[0].Association.PublicDnsName')"
    PUBLIC_IP="$(echo "$INSTANCE" | jq -cMr '.NetworkInterfaces[0].Association.PublicIp')"

    VOLUME_ID="${create_volume_if_needed}"
    attach_volume_if_needed "$VOLUME_ID" "$INSTANCE_ID"
}

function suspend() {
    INSTANCE_ID="$(get_instance_id)"
    VOLUME_ID="$(get_volume_id)"
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"

    # we need to wait for termination's completed, in case of some race conditions: suspend and resume the sandbox immedidately.
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
}

function delete() {
    INSTANCE_ID="$(get_instance_id)"
    VOLUME_ID="$(get_volume_id)"

    if [ -n "$INSTANCE_ID" ] ; then
        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
    fi

    if [ -n "$VOLUME_ID" ]; then
        aws ec2 delete-volume --volume-id "$VOLUME_ID"
    fi
}

local cmd="$1"
case "$cmd" in 
    create)
        provision >&2
        ;;
    resume)
        provision >&2
        ;;
    suspend)
        suspend >&2
        ;;
    delete)
        delete >&2
        ./cleanup.sh
        ;;
    *) fatal "Unknown command"
esac
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