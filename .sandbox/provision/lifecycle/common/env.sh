#!/bin/bash

#public_key=$(ssh-keygen -y -f ${EC2_SSH_KEY_FILE:-/run/sandbox/fs/secrets/shared/sandbox-shared.pem})
#public_key=$(ssh-keygen -y -f ${EC2_SSH_KEY_FILE:-/run/sandbox/fs/secrets/shared/ec2-keypair-shared.pem})
public_key=$(ssh-keygen -y -f ${EC2_SSH_KEY_FILE:-/run/sandbox/fs/secrets/shared/sandbox-temp.pem})
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "ssh_pub": "$public_key",
    "availablity_zone": "$AVAILABILITY_ZONE"
}
EOF
