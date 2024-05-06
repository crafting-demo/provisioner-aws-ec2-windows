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
    volume_info="$(aws ec2 describe-volumes --filters Name=tag:SandboxID,Values="$SANDBOX_ID")"
    jq -r '.Volumes[0].VolumeId' <<< $volume_info
}

function get_instance_id() {
    instances_info="$(aws ec2 describe-instances --filters Name=tag:SandboxID,Values="$SANDBOX_ID")"
    jq -r '.Reservations[0].Instances[0].InstanceId' <<< $instances_info
}

# claim_instance_from_asg claims an instance from ASG if there is no existing one claimed.
function claim_instance_from_asg() {
    # chceck is there any running instance already
    instance_with_sandbox_id="$(aws ec2 describe-instances --filters Name=tag:SandboxID,Values=$SANDBOX_ID Name=instance-state-name,Values=running)"
    if [[ $(jq '.Reservations[0].Instances | length' <<< "$instance_with_sandbox_id") -eq 0 ]]; then 
        INSTANCE_IDS="$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $ASG_NAME --no-paginate --query "AutoScalingGroups[].Instances[].InstanceId" --output text)"
        INSTANCE_ID="$(echo $INSTANCE_IDS | awk '{print $1}')"
        _="$(aws autoscaling detach-instances --instance-ids $INSTANCE_ID --auto-scaling-group-name $ASG_NAME --no-should-decrement-desired-capacity)"
        aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Sandbox,Value=$SANDBOX_NAME --tags Key=SandboxID,Value=$SANDBOX_ID
        echo $INSTANCE_ID
    else 
        jq -r '.Reservations[0].Instances[0].InstanceId' <<< $instance_with_sandbox_id
    fi
}

function attach_volume_if_needed() {
    VOLUME_ID=$1
    INSTANCE_ID=$2

    aws ec2 wait volume-available --volume-ids $VOLUME_ID
    volume="$(aws ec2 describe-volumes --volume-id $VOLUME_ID)"
    [[ $(jq ".Volumes[0].Attachments | length" <<< "$volume") -gt 0 ]] || {
        aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id $INSTANCE_ID --device "/dev/xvdf"
    }
}

# retrieve_password INSTANCE_ID KEY_FILE
function retrieve_password() {
    : ${MAX_RETRIES:=10}
    instance_id=$1
    ec2_ssh_key_file=$2

    PASSWORD_DATA="$(aws ec2 get-password-data --instance-id $instance_id)"

    retry_count=0
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        password_data="$(aws ec2 get-password-data --instance-id $instance_id | jq -r .PasswordData)"
        [[ -z "$password_data" ]] || break
        retry_count=$((retry_count + 1))
        sleep 10
    done

    aws ec2 get-password-data --instance-id $instance_id | jq -r .PasswordData | base64 -d  | openssl pkeyutl  -decrypt -inkey $ec2_ssh_key_file
}

# validate_asg ASG_NAME
function validate_asg() {
    auto_scaling_group_name=$1

    result=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $auto_scaling_group_name)
    [[ $(jq '.AutoScalingGroups | length' <<< "$result") -gt 0 ]] || fatal "Invalid auto scaling group: $auto_scaling_group_name"
}

# validate_az AZ
function validate_az() {
    availability_zone=$1
    aws ec2 describe-availability-zones --zone-name $availability_zone || fatal "Invalid availablity zone: $availability_zone"
}

# validate_ssh_key PATH
function validate_ssh_key() {
    ssh_key_path=$1

    [[ -f $ssh_key_path ]] || fatal "Invalid SSH key path: $ssh_key_path"
}

