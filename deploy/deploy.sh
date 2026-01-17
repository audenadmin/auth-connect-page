#!/bin/bash

# ============================================================================
# Auden Auth Page - Deployment Script
# ============================================================================
#
# This script deploys the auth page to AWS S3 + CloudFront.
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - Appropriate IAM permissions for S3 and CloudFront
#
# Usage:
#   ./deploy.sh auth      # Deploy to auth.auden.app
#   ./deploy.sh connect   # Deploy to connect.auden.app
#   ./deploy.sh all       # Deploy to both
#
# Environment Variables (optional):
#   AWS_PROFILE          - AWS CLI profile to use
#   AUTH_BUCKET          - S3 bucket for auth.auden.app
#   CONNECT_BUCKET       - S3 bucket for connect.auden.app
#   AUTH_DISTRIBUTION    - CloudFront distribution ID for auth
#   CONNECT_DISTRIBUTION - CloudFront distribution ID for connect
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration (override with environment variables)
AUTH_BUCKET="${AUTH_BUCKET:-auden-auth-page}"
CONNECT_BUCKET="${CONNECT_BUCKET:-auden-connect-page}"
AUTH_DISTRIBUTION="${AUTH_DISTRIBUTION:-}"
CONNECT_DISTRIBUTION="${CONNECT_DISTRIBUTION:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HTML_FILE="$PROJECT_DIR/index.html"

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           Auden Auth Page - Deployment Script                 ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    print_success "AWS CLI found"

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid."
        echo "  Run: aws configure"
        exit 1
    fi
    print_success "AWS credentials valid"

    # Check HTML file exists
    if [ ! -f "$HTML_FILE" ]; then
        print_error "HTML file not found: $HTML_FILE"
        exit 1
    fi
    print_success "HTML file found"

    echo ""
}

deploy_to_s3() {
    local bucket=$1
    local name=$2

    print_info "Deploying to S3 bucket: $bucket"

    # Upload HTML file
    aws s3 cp "$HTML_FILE" "s3://$bucket/index.html" \
        --content-type "text/html" \
        --cache-control "max-age=300, s-maxage=86400" \
        --region "$AWS_REGION"

    print_success "Uploaded index.html to s3://$bucket/"
}

invalidate_cloudfront() {
    local distribution_id=$1
    local name=$2

    if [ -z "$distribution_id" ]; then
        print_warning "No CloudFront distribution ID provided for $name. Skipping invalidation."
        echo "  Set ${name^^}_DISTRIBUTION environment variable to enable."
        return
    fi

    print_info "Invalidating CloudFront distribution: $distribution_id"

    aws cloudfront create-invalidation \
        --distribution-id "$distribution_id" \
        --paths "/*" \
        --region "$AWS_REGION" \
        --output text > /dev/null

    print_success "CloudFront invalidation created for $name"
}

deploy_auth() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Deploying to auth.auden.app${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    deploy_to_s3 "$AUTH_BUCKET" "auth"
    invalidate_cloudfront "$AUTH_DISTRIBUTION" "auth"

    print_success "auth.auden.app deployment complete!"
}

deploy_connect() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Deploying to connect.auden.app${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    deploy_to_s3 "$CONNECT_BUCKET" "connect"
    invalidate_cloudfront "$CONNECT_DISTRIBUTION" "connect"

    print_success "connect.auden.app deployment complete!"
}

show_usage() {
    echo "Usage: $0 <target>"
    echo ""
    echo "Targets:"
    echo "  auth     Deploy to auth.auden.app only"
    echo "  connect  Deploy to connect.auden.app only"
    echo "  all      Deploy to both domains"
    echo ""
    echo "Environment Variables:"
    echo "  AWS_PROFILE          AWS CLI profile to use"
    echo "  AUTH_BUCKET          S3 bucket for auth.auden.app (default: auden-auth-page)"
    echo "  CONNECT_BUCKET       S3 bucket for connect.auden.app (default: auden-connect-page)"
    echo "  AUTH_DISTRIBUTION    CloudFront distribution ID for auth"
    echo "  CONNECT_DISTRIBUTION CloudFront distribution ID for connect"
    echo "  AWS_REGION           AWS region (default: us-east-1)"
    echo ""
}

# ============================================================================
# Main
# ============================================================================

print_header

# Check for target argument
if [ -z "$1" ]; then
    print_error "No deployment target specified."
    echo ""
    show_usage
    exit 1
fi

TARGET="$1"

# Run prerequisites check
check_prerequisites

# Deploy based on target
case "$TARGET" in
    auth)
        deploy_auth
        ;;
    connect)
        deploy_connect
        ;;
    all)
        deploy_auth
        deploy_connect
        ;;
    *)
        print_error "Unknown target: $TARGET"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Deployment completed successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
