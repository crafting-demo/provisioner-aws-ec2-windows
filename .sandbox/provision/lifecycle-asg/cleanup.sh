#!/bin/bash

source ./common.sh

# cleanup leaked instances
echo "Checking and cleaning up the leaked instances (if any)"
cleanup()
