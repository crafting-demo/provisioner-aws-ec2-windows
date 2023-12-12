#!/bin/bash

public_key=$(ssh-add -L)
cat <<EOF
{
    "sandbox_id": "$SANDBOX_ID",
    "sandbox_name": "$SANDBOX_NAME",
    "ssh_pub": "$public_key"
}
EOF