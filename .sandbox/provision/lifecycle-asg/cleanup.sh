#!/bin/bash

set -ex

source .sandbox/provision/lifecycle-asg/common.sh

# cleanup leaked instances
echo "Checking and cleaning up the leaked instances (if any)"
cleanup
