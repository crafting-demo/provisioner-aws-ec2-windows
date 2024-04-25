#!/bin/bash

public_key=$(ssh-keygen -y -f ${EC2_SSH_KEY_FILE:-/run/sandbox/fs/secrets/shared/employ-shared.pem})
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "ssh_pub": "$public_key",
    "availablity_zone": "$AVAILABILITY_ZONE"
}
EOF

