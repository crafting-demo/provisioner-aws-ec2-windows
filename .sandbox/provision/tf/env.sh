#!/bin/bash

public_key=$(ssh-keygen -y -f /run/sandbox/fs/secrets/shared/sandbox-shared.pem)
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "ssh_pub": "$public_key"
}
EOF