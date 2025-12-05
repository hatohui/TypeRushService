#!/usr/bin/env bash
set -euo pipefail

# Simple packaging helper for local bootstrapping
# - Creates a 'build' directory at repo root (./build)
# - Zips record-service and text-service into build/ as expected by Terraform default paths

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
BUILD_DIR="${ROOT_DIR}/build"

mkdir -p "${BUILD_DIR}"

echo "Packaging record-service..."
if [ -d "${ROOT_DIR}/services/record-service" ]; then
  SRV_DIR="${ROOT_DIR}/services/record-service"
  # Use a temporary staging directory so we don't pollute the source tree
  TMP_DIR=$(mktemp -d)
  echo " -> Staging files into: ${TMP_DIR}"

  # Basic copy (preserve source files, but omit node_modules if present)
  rsync -a --exclude 'node_modules' --exclude '.git' "${SRV_DIR}/" "${TMP_DIR}/"

  # If package.json exists and npm is available, run a production install and build in the staging dir
  if [ -f "${SRV_DIR}/package.json" ] && command -v npm >/dev/null 2>&1; then
    echo " -> package.json detected: running npm ci (production) and npm run build if available"
    pushd "${TMP_DIR}" >/dev/null
    # Install only production deps to keep artifact small (if package.json present)
    if npm ci --production >/dev/null 2>&1; then
      echo "    npm ci --production succeeded"
    else
      echo "    npm ci --production failed or no package-lock.json — attempting npm install --production"
      npm install --production || true
    fi

    # Try build (non-fatal)
    if npm run build >/dev/null 2>&1; then
      echo "    npm run build succeeded"
    else
      echo "    npm run build not present or failed — continuing (no build output may be present)"
    fi
    popd >/dev/null
  else
    echo " -> No package.json or npm not available; zipping repository files as-is"
  fi

  (cd "${TMP_DIR}" && zip -r "${BUILD_DIR}/record-service-lambda.zip" . -x "*/.git/*" -x "*/node_modules/*")
  echo " -> ${BUILD_DIR}/record-service-lambda.zip"

  rm -rf "${TMP_DIR}"
else
  echo "WARNING: services/record-service not present — skipping"
fi

echo "Packaging text-service..."
if [ -d "${ROOT_DIR}/services/text-service" ]; then
  TXT_DIR="${ROOT_DIR}/services/text-service"
  TMP_DIR=$(mktemp -d)
  echo " -> Staging files into: ${TMP_DIR}"

  rsync -a --exclude '.git' --exclude '__pycache__' "${TXT_DIR}/" "${TMP_DIR}/"

  # If requirements.txt exists and pip is available, install dependencies into staging dir
  if [ -f "${TXT_DIR}/requirements.txt" ] && command -v pip >/dev/null 2>&1; then
    echo " -> requirements.txt detected: installing into staging dir"
    pip install -r "${TXT_DIR}/requirements.txt" --target "${TMP_DIR}" || true
  else
    echo " -> No requirements.txt or pip not available; zipping repository files as-is"
  fi

  (cd "${TMP_DIR}" && zip -r "${BUILD_DIR}/text-service-lambda.zip" . -x "**/__pycache__/**")
  echo " -> ${BUILD_DIR}/text-service-lambda.zip"

  rm -rf "${TMP_DIR}"
else
  echo "WARNING: services/text-service not present — skipping"
fi

echo "Packaging complete. Build artifacts are in ${BUILD_DIR}"

if [ "$#" -gt 0 ] && [ "$1" = "upload" ]; then
  if [ -z "${AWS_PROFILE:-}" ] && [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
    echo "Uploading requires AWS CLI credentials (AWS_PROFILE or env vars). Aborting upload."
    exit 1
  fi
  BUCKET_NAME="${2:-}" && BUCKET_NAME=${BUCKET_NAME:-}
  if [ -z "${BUCKET_NAME}" ]; then
    echo "Specify target S3 bucket name as second parameter when using 'upload'"
    exit 1
  fi

  echo "Uploading artifacts to s3://${BUCKET_NAME}/"
  aws s3 cp "${BUILD_DIR}/record-service-lambda.zip" "s3://${BUCKET_NAME}/record-service-lambda.zip" || true
  aws s3 cp "${BUILD_DIR}/text-service-lambda.zip" "s3://${BUCKET_NAME}/text-service-lambda.zip" || true
  echo "Upload finished"
fi

exit 0