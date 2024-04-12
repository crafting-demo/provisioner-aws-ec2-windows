#!/bin/bash

public_key=$(ssh-keygen -y -f ${EC2_SSH_KEY_FILE:-/run/sandbox/fs/secrets/shared/sandbox-shared.pem})
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "ssh_pub": "$public_key"
}
EOF
