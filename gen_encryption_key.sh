#!/bin/bash

# Original boilerplate from https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/data_source

# Exit if any of the intermediate steps fail
set -e

# Placeholder for whatever data-fetching logic your script implements
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg encryption_key "$ENCRYPTION_KEY" '{"encryption_key":$encryption_key}'
