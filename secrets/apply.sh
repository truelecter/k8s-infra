#!/bin/bash

if [ -z "$SECRETS_CONTEXT" ]; then
  echo "\$SECRETS_CONTEXT environment variable is required!"
  exit 1
fi

if ! kubectl --context $SECRETS_CONTEXT get pods -A > /dev/null 2>&1; then
  echo "Unable to connect to kubernetes server"
  exit 1
fi

SECRETS_DIR="$( dirname -- $(realpath $BASH_SOURCE) )/manifests"

for filename in $SECRETS_DIR/*; do
  sops -d $filename | kubectl --context $SECRETS_CONTEXT apply -f -
done