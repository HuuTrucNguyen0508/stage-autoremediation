#!/usr/bin/env bash
set -euo pipefail

# Idempotently ensures the S3 bucket and DynamoDB table for Terraform backend exist.
# Defaults match backend.tf. Override via env or flags.
#
# Usage:
#   AWS_REGION=us-east-1 STATE_BUCKET=my-bucket LOCK_TABLE=my-locks \
#     bash terraform/bootstrap-backend.sh
#   OR
#   bash terraform/bootstrap-backend.sh --region us-east-1 \
#     --bucket my-bucket --table my-locks

AWS_REGION="${AWS_REGION:-us-east-1}"
STATE_BUCKET="${STATE_BUCKET:-truh1-terraform-state}"
LOCK_TABLE="${LOCK_TABLE:-truh1-terraform-locks}"

usage() {
  cat <<EOF
Bootstrap Terraform remote backend resources (S3 + DynamoDB)

Options:
  --region <aws-region>   AWS region (default: ${AWS_REGION})
  --bucket <name>         S3 bucket for state (default: ${STATE_BUCKET})
  --table <name>          DynamoDB table for locks (default: ${LOCK_TABLE})
  -h, --help              Show this help

Env vars (override defaults or flags): AWS_REGION, STATE_BUCKET, LOCK_TABLE
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      AWS_REGION="$2"; shift 2 ;;
    --bucket)
      STATE_BUCKET="$2"; shift 2 ;;
    --table)
      LOCK_TABLE="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage; exit 1 ;;
  esac
done

require_aws() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLI not found. Install AWS CLI v2 and configure credentials." >&2
    exit 1
  fi
}

create_bucket_if_missing() {
  if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo "S3 bucket exists: $STATE_BUCKET"
  else
    echo "Creating S3 bucket: $STATE_BUCKET in region $AWS_REGION"
    if [[ "$AWS_REGION" == "us-east-1" ]]; then
      aws s3api create-bucket --bucket "$STATE_BUCKET"
    else
      aws s3api create-bucket --bucket "$STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
  fi

  local versioning_status
  versioning_status=$(aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" --query 'Status' --output text 2>/dev/null || true)
  if [[ "$versioning_status" != "Enabled" ]]; then
    echo "Enabling versioning on bucket: $STATE_BUCKET"
    aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" \
      --versioning-configuration Status=Enabled
  fi

  if ! aws s3api get-bucket-encryption --bucket "$STATE_BUCKET" >/dev/null 2>&1; then
    echo "Enabling SSE-S3 encryption on bucket: $STATE_BUCKET"
    aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  fi
}

create_lock_table_if_missing() {
  if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "DynamoDB table exists: $LOCK_TABLE"
  else
    echo "Creating DynamoDB table: $LOCK_TABLE in region $AWS_REGION"
    aws dynamodb create-table \
      --table-name "$LOCK_TABLE" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$AWS_REGION"
    echo "Waiting for table to become ACTIVE..."
    aws dynamodb wait table-exists --table-name "$LOCK_TABLE" --region "$AWS_REGION"
  fi
}

echo "Using AWS_REGION=$AWS_REGION STATE_BUCKET=$STATE_BUCKET LOCK_TABLE=$LOCK_TABLE"
require_aws
create_bucket_if_missing
create_lock_table_if_missing
echo "Backend bootstrap complete."


