#!/bin/bash

set -ex

source ./common.sh

# cleanup leaked instances
echo "Checking and cleaning up the leaked instances (if any)"
cleanup()
