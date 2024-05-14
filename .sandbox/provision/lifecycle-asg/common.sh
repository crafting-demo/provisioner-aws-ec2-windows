#!/bin/bash

: ${MAX_RETRIES:=30}
: ${VOLUME_SIZE:=10}
: ${DEVICE_NAME:="/dev/xvdf"}
: ${SANDBOX_NAME_TAG:="SandboxManaged-SandboxName"}
: ${SANDBOX_ID_TAG:="SandboxManaged-SandboxID"}
: ${SANDBOX_ASG_TAG:="sandbox-asg"}

function fatal() {
    echo "$@" >&2
    exit 1
}

function process_response() {
    local response
    if (( $# == 0 )) ; then
        response="$(< /dev/stdin)"
    else
        response="$1"
    fi

    if [[ "$response" = "None" ]]; then
        response=""
    fi
    echo "$response"
}

function get_volume_id() {
    aws ec2 describe-volumes --filters Name=tag:"$SANDBOX_ID_TAG",Values="$SANDBOX_ID" --query 'Volumes[0].VolumeId' --output text | process_response
}

function create_volume_if_needed() {
    local volume_id="$(get_volume_id)"
    if [[ -z "$volume_id" ]]; then
        volume_id="$(aws ec2 create-volume --size "$VOLUME_SIZE" --availability-zone "$AVAILABILITY_ZONE" --tag-specification "ResourceType=volume,Tags=[{Key=$SANDBOX_ID_TAG,Value="$SANDBOX_ID"}]" --query "VolumeId" --output text | process_response)"
    fi
    echo "$volume_id"
}

function delete_volume() {
    local volume_id="$(get_volume_id)"
    [[ -z "$volume_id" ]] || aws ec2 delete-volume --volume-id "$volume_id"
}

function get_instance_id() {
    aws ec2 describe-instances --filters Name=tag:"$SANDBOX_ID_TAG",Values="$SANDBOX_ID" Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].InstanceId' --output text | process_response
}

function terminate_instance() {
    local instance_id
    instance_id="$(get_instance_id)"
    [[ -z "$instance_id" ]] || {
        aws ec2 terminate-instances --instance-ids "$instance_id"
        aws ec2 wait instance-terminated --instance-ids "$instance_id"
    }
}

# claim_instance_from_asg claims an instance from ASG if there is no existing one claimed.
function claim_instance_from_asg() {
    # check is there any running instance already
    local instance_with_sandbox_id
    instance_with_sandbox_id="$(aws ec2 describe-instances --filters Name=tag:"$SANDBOX_ID_TAG",Values="$SANDBOX_ID" Name=instance-state-name,Values=running)"
    if [[ "$(jq -cMr '.Reservations[0].Instances | length' <<< "$instance_with_sandbox_id")" -eq 0 ]]; then 
        local instance_id
        instance_id="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$ASG_NAME" --no-paginate --query AutoScalingGroups[0].Instances[0].InstanceId --output text)"

        # detach-instances is an atomic operation and a single instance can not be deatched twice. 
        # This mechanism is used to prevent race condition between two or more claims that happening at the same time. The second claim would fail.
        aws autoscaling detach-instances --instance-ids "$instance_id" --auto-scaling-group-name "$ASG_NAME" --no-should-decrement-desired-capacity >/dev/null

        # Two tags are created for the detached instance
        # - Sandbox, this is for referencing purpose and should not be used as an ID during looking up.
        # - SandboxID, this is the actual identification of the EC2 instance.
        # An EC2 instance is deemed as leaked if:
        # - SandboxID tag is missing
        # - Some ASG flagging tag exists, e.g. sandbox-asg=true
        # - The instance is detached from ASG.
        aws ec2 create-tags --resources "$instance_id" --tags Key="$SANDBOX_NAME_TAG",Value="$SANDBOX_NAME" --tags Key="$SANDBOX_ID_TAG",Value="$SANDBOX_ID"

        echo "$instance_id"
    else 
        jq -cMr '.Reservations[0].Instances[0].InstanceId' <<< "$instance_with_sandbox_id"
    fi
}

function attach_volume_if_needed() {
    local volume_id="$1"
    local instance_id="$2"

    aws ec2 wait volume-available --volume-ids "$volume_id"
    [[ $(aws ec2 describe-volumes --volume-id "$volume_id" --query "Volumes[0].Attachments" | jq 'length') -gt 0 ]] || {
        aws ec2 attach-volume --volume-id "$volume_id" --instance-id "$instance_id" --device "$DEVICE_NAME"
    }
}

# retrieve_password INSTANCE_ID KEY_FILE
function retrieve_password() {
    local instance_id="$1"
    local ec2_ssh_key_file="$2"
    local password_data

    password_data="$(aws ec2 get-password-data --instance-id "$instance_id" --query 'PasswordData' --output text)"

    local retry_count=0
    while [[ "$retry_count" -lt "$MAX_RETRIES" ]]; do
        password_data="$(aws ec2 get-password-data --instance-id "$instance_id" --query 'PasswordData' --output text)"
        [[ -z "$password_data" ]] || break
        retry_count=$((retry_count + 1))
        sleep 10
    done

    [[ -n "$password_data" ]] || fatal "Unable to get password data"
    
    echo "$password_data" | base64 -d  | openssl pkeyutl  -decrypt -inkey "$ec2_ssh_key_file"
}

# validate_asg ASG_NAME
function validate_asg() {
    local auto_scaling_group_name="$1"
    [[ $(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$auto_scaling_group_name" --query 'AutoScalingGroups' | jq 'length') -gt 0 ]] || fatal "Invalid auto scaling group: $auto_scaling_group_name"
}

# validate_az AZ
function validate_az() {
    local availability_zone="$1"
    aws ec2 describe-availability-zones --zone-name "$availability_zone" || fatal "Invalid availablity zone: $availability_zone"
}

# validate_ssh_key PATH
function validate_ssh_key() {
    local ssh_key_path="$1"

    [[ -f "$ssh_key_path" ]] || fatal "Invalid SSH key path: $ssh_key_path"
}

function cleanup() {
    local instance_ids
    instance_ids="$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag:$SANDBOX_ASG_TAG,Values=true" --query "Reservations[].Instances[?!(Tags[?Key=='aws:autoscaling:groupName'] || Tags[?Key=='$SANDBOX_ID_TAG'])].InstanceId[]" --output text)" 
    [[ -z "$instance_ids" ]] || aws ec2 terminate-instances --instance-ids $instance_ids
}
