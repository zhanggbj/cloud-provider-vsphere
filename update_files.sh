#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 --capi <CAPI_VERSION> --capv <CAPV_VERSION>"
  echo "Example: $0 --capi v1.10.0-rc.0 --capv v1.13.0-rc.0"
  exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --capi) CAPI_VERSION="$2"; shift ;;
    --capv) CAPV_VERSION="$2"; shift ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
  shift
done

# Validate arguments
if [[ -z "$CAPI_VERSION" || -z "$CAPV_VERSION" ]]; then
  echo "Error: Both --capi and --capv flags are required."
  usage
fi

# Detect the operating system
OS=$(uname)

# Set the sed command based on the OS
if [[ "$OS" == "Darwin" ]]; then
  SED_COMMAND="sed -i ''"
elif [[ "$OS" == "Linux" ]]; then
  SED_COMMAND="sed -i"
else
  echo "Unsupported operating system: $OS"
  exit 1
fi

# Update Makefile
MAKEFILE="test/e2e/Makefile"
if [ -f "$MAKEFILE" ]; then
  $SED_COMMAND "s/E2E_DATA_CAPV_TAG ?= v[0-9.]*[a-z0-9.-]*/E2E_DATA_CAPV_TAG ?= $CAPV_VERSION/" "$MAKEFILE"
  echo "Updated $MAKEFILE"
else
  echo "File $MAKEFILE not found!"
fi

# Update vsphere-ci.yaml
CONFIG_FILE="test/e2e/config/vsphere-ci.yaml"
if [ -f "$CONFIG_FILE" ]; then
  $SED_COMMAND "s/  - name: v[0-9.]*[a-z0-9.-]*/  - name: ${CAPI_VERSION//./99}/" "$CONFIG_FILE"
  $SED_COMMAND "s|https://github.com/kubernetes-sigs/cluster-api/releases/download/v[0-9.]*[a-z0-9.-]*/core-components.yaml|https://github.com/kubernetes-sigs/cluster-api/releases/download/$CAPI_VERSION/core-components.yaml|" "$CONFIG_FILE"
  $SED_COMMAND "s|../data/shared/capi/v[0-9.]*/metadata.yaml|../data/shared/capi/${CAPI_VERSION//./}/metadata.yaml|" "$CONFIG_FILE"
  $SED_COMMAND "s|https://github.com/kubernetes-sigs/cluster-api/releases/download/v[0-9.]*[a-z0-9.-]*/bootstrap-components.yaml|https://github.com/kubernetes-sigs/cluster-api/releases/download/$CAPI_VERSION/bootstrap-components.yaml|" "$CONFIG_FILE"
  $SED_COMMAND "s|https://github.com/kubernetes-sigs/cluster-api/releases/download/v[0-9.]*[a-z0-9.-]*/control-plane-components.yaml|https://github.com/kubernetes-sigs/cluster-api/releases/download/$CAPI_VERSION/control-plane-components.yaml|" "$CONFIG_FILE"
  echo "Updated $CONFIG_FILE"
else
  echo "File $CONFIG_FILE not found!"
fi

echo "Changes applied successfully."