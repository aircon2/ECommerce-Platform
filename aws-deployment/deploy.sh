#!/bin/bash

# AWS E-commerce Analytics Platform Deployment Script
# This script deploys the complete AWS infrastructure for the e-commerce analytics project

set -e  # Exit on any error

# Configuration
ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
STACK_NAME="ecommerce-analytics-${ENVIRONMENT}"
TEMPLATE_FILE="aws-infrastructure/cloudformation-template.yaml"
PARAMETER_FILE="aws-infrastructure/parameters-${ENVIRONMENT}.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create parameters file if it doesn't exist
create_parameters_file() {
    if [ ! -f "$PARAMETER_FILE" ]; then
        log_info "Creating parameters file for $ENVIRONMENT environment..."
        cat > "$PARAMETER_FILE" << EOF
[
  {
    "ParameterKey": "Environment",
    "ParameterValue": "$ENVIRONMENT"
  },
  {
    "ParameterKey": "DatabasePassword",
    "ParameterValue": "$(openssl rand -base64 32)"
  }
]
EOF
        log_success "Parameters file created: $PARAMETER_FILE"
    fi
}

# Deploy CloudFormation stack
deploy_stack() {
    log_info "Deploying CloudFormation stack: $STACK_NAME"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
        log_info "Stack exists. Updating..."
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$PARAMETER_FILE" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION"
        
        log_info "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"
    else
        log_info "Stack doesn't exist. Creating..."
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body "file://$TEMPLATE_FILE" \
            --parameters "file://$PARAMETER_FILE" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION"
        
        log_info "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete \
            --stack-name "$STACK_NAME" \
            --region "$REGION"
    fi
    
    log_success "Stack deployment completed"
}

# Get stack outputs
get_stack_outputs() {
    log_info "Retrieving stack outputs..."
    
    aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs' \
        --output table
}

# Deploy Lambda function
deploy_lambda() {
    log_info "Deploying Lambda function..."
    
    # Create deployment package
    cd aws-lambda
    zip -r data-processor.zip data_processor.py
    cd ..
    
    # Get function name from stack outputs
    FUNCTION_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionArn`].OutputValue' \
        --output text | cut -d':' -f7)
    
    # Update function code
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://aws-lambda/data-processor.zip" \
        --region "$REGION"
    
    log_success "Lambda function deployed"
}

# Set up Glue job
setup_glue_job() {
    log_info "Setting up Glue ETL job..."
    
    # Create Glue job
    aws glue create-job \
        --name "ecommerce-analytics-etl-${ENVIRONMENT}" \
        --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/${ENVIRONMENT}-ecommerce-lambda-role" \
        --command '{
            "Name": "glueetl",
            "ScriptLocation": "s3://aws-glue-scripts-$(aws sts get-caller-identity --query Account --output text)-us-east-1/ecommerce_etl.py",
            "PythonVersion": "3"
        }' \
        --default-arguments '{
            "--job-language": "python",
            "--job-bookmark-option": "job-bookmark-enable",
            "--enable-metrics": "true"
        }' \
        --max-capacity 2 \
        --region "$REGION" || log_warning "Glue job may already exist"
    
    log_success "Glue job setup completed"
}

# Create QuickSight data source
setup_quicksight() {
    log_info "Setting up QuickSight data source..."
    
    # Note: QuickSight setup requires manual configuration through the console
    # This script provides the configuration file
    log_warning "QuickSight setup requires manual configuration through the AWS Console"
    log_info "Use the configuration file: aws-quicksight/dashboard_config.json"
    
    # Get S3 bucket name for reference
    BUCKET_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`DataLakeBucketName`].OutputValue' \
        --output text)
    
    log_info "S3 Data Lake Bucket: $BUCKET_NAME"
}

# Initialize database
initialize_database() {
    log_info "Initializing database with sample data..."
    
    # Get RDS endpoint
    DB_ENDPOINT=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`DatabaseEndpoint`].OutputValue' \
        --output text)
    
    # Get database password from parameters
    DB_PASSWORD=$(jq -r '.[] | select(.ParameterKey=="DatabasePassword") | .ParameterValue' "$PARAMETER_FILE")
    
    log_info "Database endpoint: $DB_ENDPOINT"
    log_warning "Please manually run the database initialization scripts:"
    log_info "1. database_schema.sql"
    log_info "2. sample_data.sql"
    log_info "3. analytics_queries.sql"
    log_info "Connection details:"
    log_info "  Host: $DB_ENDPOINT"
    log_info "  Port: 3306"
    log_info "  Database: ecommerce_analytics"
    log_info "  Username: admin"
    log_info "  Password: [stored in $PARAMETER_FILE]"
}

# Main deployment function
main() {
    log_info "Starting AWS E-commerce Analytics Platform deployment"
    log_info "Environment: $ENVIRONMENT"
    log_info "Region: $REGION"
    log_info "Stack Name: $STACK_NAME"
    
    check_prerequisites
    create_parameters_file
    deploy_stack
    get_stack_outputs
    deploy_lambda
    setup_glue_job
    setup_quicksight
    initialize_database
    
    log_success "Deployment completed successfully!"
    log_info "Next steps:"
    log_info "1. Initialize the database with sample data"
    log_info "2. Configure QuickSight data sources"
    log_info "3. Test the Lambda function"
    log_info "4. Run the Glue ETL job"
    log_info "5. Create QuickSight dashboards"
}

# Run main function
main "$@"
