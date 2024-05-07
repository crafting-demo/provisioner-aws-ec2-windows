#!/bin/bash

function fatal() {
  echo "$@" >&2
  exit 1
}

function redirect_stdout() {
    exec 3>&1
    exec 1>&2
}

function restore_stdout() {
    exec 1>&3
    exec 3>&-
}

function get_volume_id() {
    local volume_info="$(aws ec2 describe-volumes --filters Name=tag:SandboxID,Values="$SANDBOX_ID")"
    jq -cMr '.Volumes[0].VolumeId' <<< "$volume_info"
}

function get_instance_id() {
    local instances_info="$(aws ec2 describe-instances --filters Name=tag:SandboxID,Values="$SANDBOX_ID")"
    jq -cMr '.Reservations[0].Instances[0].InstanceId' <<< "$instances_info"
}

# claim_instance_from_asg claims an instance from ASG if there is no existing one claimed.
function claim_instance_from_asg() {
    # check is there any running instance already
    local instance_with_sandbox_id="$(aws ec2 describe-instances --filters Name=tag:SandboxID,Values="$SANDBOX_ID" Name=instance-state-name,Values=running)"
    if [[ "$(jq -cMr '.Reservations[0].Instances | length' <<< "$instance_with_sandbox_id")" -eq 0 ]]; then 
        local instance_ids="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$ASG_NAME" --no-paginate --query "AutoScalingGroups[].Instances[].InstanceId" --output text)"
        local instance_id="$(echo "$instance_ids" | awk '{print $1}')"

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
        aws ec2 create-tags --resources "$instance_id" --tags Key=Sandbox,Value="$SANDBOX_NAME" --tags Key=SandboxID,Value="$SANDBOX_ID"

        echo "$instance_id"
    else 
        jq -cMr '.Reservations[0].Instances[0].InstanceId' <<< "$instance_with_sandbox_id"
    fi
}

function attach_volume_if_needed() {
    local volume_id=$1
    local instance_id=$2

    aws ec2 wait volume-available --volume-ids "$volume_id"
    local volume="$(aws ec2 describe-volumes --volume-id "$volume_id")"
    [[ "$(jq -cMr ".Volumes[0].Attachments | length" <<< "$volume")" -gt 0 ]] || {
        aws ec2 attach-volume --volume-id "$volume_id" --instance-id "$instance_id" --device "/dev/xvdf"
    }
}

# retrieve_password INSTANCE_ID KEY_FILE
function retrieve_password() {
    : ${MAX_RETRIES:=10}
    local instance_id=$1
    local ec2_ssh_key_file=$2

    local password_data="$(aws ec2 get-password-data --instance-id "$instance_id")"

    local retry_count=0
    while [[ "$retry_count" -lt "$MAX_RETRIES" ]]; do
        password_data="$(aws ec2 get-password-data --instance-id "$instance_id" | jq -cMr .PasswordData)"
        [[ -z "$password_data" ]] || break
        retry_count=$((retry_count + 1))
        sleep 10
    done

    aws ec2 get-password-data --instance-id "$instance_id" | jq -r .PasswordData | base64 -d  | openssl pkeyutl  -decrypt -inkey "$ec2_ssh_key_file"
}

# validate_asg ASG_NAME
function validate_asg() {
    local auto_scaling_group_name=$1

    local result="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$auto_scaling_group_name")"
    [[ $(jq -cMr '.AutoScalingGroups | length' <<< "$result") -gt 0 ]] || fatal "Invalid auto scaling group: $auto_scaling_group_name"
}

# validate_az AZ
function validate_az() {
    local availability_zone=$1
    aws ec2 describe-availability-zones --zone-name "$availability_zone" || fatal "Invalid availablity zone: $availability_zone"
}

# validate_ssh_key PATH
function validate_ssh_key() {
    local ssh_key_path=$1

    [[ -f $ssh_key_path ]] || fatal "Invalid SSH key path: $ssh_key_path"
}
