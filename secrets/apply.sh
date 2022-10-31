#!/bin/bash

if [ -z "$SECRETS_CONTEXT" ]; then
  echo "\$SECRETS_CONTEXT environment variable is required!"
  exit 1
fi

if ! kubectl --context $SECRETS_CONTEXT get pods -A > /dev/null 2>&1; then
  echo "Unable to connect to kubernetes server"
  exit 1
fi

SECRETS_BASE_DIR="$PRJ_ROOT/secrets"

for filename in $SECRETS_BASE_DIR/manifests/*; do
  sops -d $filename | kubectl --context $SECRETS_CONTEXT apply -f -
done

for filename in $SECRETS_BASE_DIR/sops-operator/*; do
  kubectl --context $SECRETS_CONTEXT apply -f $filename
done