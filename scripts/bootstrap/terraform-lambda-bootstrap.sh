#!/usr/bin/env bash
set -euo pipefail

# terraform-lambda-bootstrap.sh
# Safely create the artifacts bucket, package lambda ZIPs, upload them, and apply the lambda module.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
INFRAS_DIR="${ROOT_DIR}/infras"

AUTO_APPROVE=false
SKIP_UPLOAD=false
PROJECT=""
ENV=""

usage() {
  cat <<EOF
Usage: $0 [--auto-approve] [--skip-upload] [--project <project>] [--env <environment>]

Description:
  - Runs 'terraform apply -target=module.codepipeline' to create the artifacts bucket
  - Packages local lambda zips (./scripts/bootstrap/package-lambdas.sh)
  - Uploads zip files to the artifacts bucket
  - Runs 'terraform apply -target=module.lambda' to deploy lambdas

If project/env are not passed, the script will try to read infras/dev.auto.tfvars for defaults.
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --auto-approve) AUTO_APPROVE=true; shift ;;
    --skip-upload) SKIP_UPLOAD=true; shift ;;
    --project) PROJECT="$2"; shift 2 ;;
    --env) ENV="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

# Read defaults from infras/dev.auto.tfvars if needed
if [ -z "$PROJECT" ] || [ -z "$ENV" ]; then
  if [ -f "${INFRAS_DIR}/dev.auto.tfvars" ]; then
    PROJECT_VAL=$(grep -E '^project_name' "${INFRAS_DIR}/dev.auto.tfvars" | sed -E "s/.*=\s*\"?([^\" ]+)\"?/\1/") || true
    ENV_VAL=$(grep -E '^environment' "${INFRAS_DIR}/dev.auto.tfvars" | sed -E "s/.*=\s*\"?([^\" ]+)\"?/\1/") || true
    PROJECT=${PROJECT:-$PROJECT_VAL}
    ENV=${ENV:-$ENV_VAL}
  fi
fi

if [ -z "$PROJECT" ] || [ -z "$ENV" ]; then
  echo "ERROR: Could not determine project or environment. Pass --project and --env or provide in infras/dev.auto.tfvars."
  exit 2
fi

BUCKET_NAME="${PROJECT}-${ENV}-pipeline-artifacts"

echo "Using project=${PROJECT} env=${ENV} -> artifacts bucket: ${BUCKET_NAME}"

cd "${INFRAS_DIR}"

TF_AUTO_APPROVE_FLAG=""
$AUTO_APPROVE && TF_AUTO_APPROVE_FLAG="-auto-approve"

echo "Initializing terraform in ${INFRAS_DIR}..."
terraform init -input=false

echo "Applying module.codepipeline (creates artifacts bucket)..."
terraform apply -target=module.codepipeline $TF_AUTO_APPROVE_FLAG -input=false

if [ "$SKIP_UPLOAD" = true ]; then
  echo "Skip upload requested — exiting after creating bucket."
  exit 0
fi

echo "Packaging local lambda artifacts (scripts/bootstrap/package-lambdas.sh)..."
"${ROOT_DIR}/scripts/bootstrap/package-lambdas.sh"

if [ ! -f "${ROOT_DIR}/build/record-service-lambda.zip" ] && [ ! -f "${ROOT_DIR}/build/text-service-lambda.zip" ]; then
  echo "ERROR: No artifacts found in ${ROOT_DIR}/build — nothing to upload"
  echo "Hint: run ${ROOT_DIR}/scripts/bootstrap/package-lambdas.sh to create artifacts, or upload packages to the artifacts bucket and enable S3 mode in the lambda module variables."
  exit 4
else
  echo "Uploading artifacts to s3://${BUCKET_NAME}/"
  if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: aws cli not found; install and configure credentials to upload artifacts"
    exit 3
  fi

  if [ -f "${ROOT_DIR}/build/record-service-lambda.zip" ]; then
    aws s3 cp "${ROOT_DIR}/build/record-service-lambda.zip" "s3://${BUCKET_NAME}/record-service-lambda.zip"
  fi

  if [ -f "${ROOT_DIR}/build/text-service-lambda.zip" ]; then
    aws s3 cp "${ROOT_DIR}/build/text-service-lambda.zip" "s3://${BUCKET_NAME}/text-service-lambda.zip"
  fi
fi

echo "Applying module.lambda to deploy functions pointing at S3 objects / local files..."
terraform apply -target=module.lambda $TF_AUTO_APPROVE_FLAG -input=false

echo "Bootstrap sequence completed. Review terraform apply results and logs if needed."

exit 0
