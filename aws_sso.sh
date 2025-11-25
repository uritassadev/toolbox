#!/bin/bash
# Default values
DEFAULT_REGION="us-east-2"
DEFAULT_OUTPUT="json"
DEFAULT_SSO_URL="https://d-9a67623f6b.awsapps.com/start"

# Function to display usage
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -p, --profile AWS profile name (required)"
    echo "  -u, --sso-url SSO start URL (default: $DEFAULT_SSO_URL)"
    echo "  -r, --region AWS region (default: $DEFAULT_REGION)"
    echo "  -o, --output CLI output format (default: $DEFAULT_OUTPUT)"
    echo "  -h, --help Display this help message"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--profile)
            PROFILE_NAME="$2"
            shift 2
            ;;
        -u|--sso-url)
            SSO_URL="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -o|--output)
            CLI_OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Set default values if not provided
AWS_REGION=${AWS_REGION:-$DEFAULT_REGION}
CLI_OUTPUT_FORMAT=${CLI_OUTPUT_FORMAT:-$DEFAULT_OUTPUT}
SSO_URL=${SSO_URL:-$DEFAULT_SSO_URL}

# Validate required parameters
if [ -z "$PROFILE_NAME" ]; then
    echo "Error: Profile name is required"
    usage
    exit 1
fi

# Check AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

echo "Setting up SSO configuration for profile: $PROFILE_NAME"

# Set basic configuration
aws configure set region "$AWS_REGION" --profile "$PROFILE_NAME"
aws configure set output "$CLI_OUTPUT_FORMAT" --profile "$PROFILE_NAME"
aws configure set sso_start_url "$SSO_URL" --profile "$PROFILE_NAME"
aws configure set sso_region "$AWS_REGION" --profile "$PROFILE_NAME"

# Perform SSO login
echo "Starting AWS SSO login process for profile: $PROFILE_NAME"
echo "This will open a browser window. Please complete the login process there."
echo "After login, you may be asked to select an AWS account and role."

if aws sso login --profile "$PROFILE_NAME"; then
    echo "SSO login process completed."
    echo "Checking credentials..."
    
    # Small delay to allow credentials to be processed
    sleep 3
    
    # Check if credentials are valid
    if aws sts get-caller-identity --profile "$PROFILE_NAME" &> /dev/null; then
        echo "✅ SSO login successful!"
        echo "Profile '$PROFILE_NAME' is ready to use."
        
        # Display account information
        echo "Account Information:"
        aws sts get-caller-identity --profile "$PROFILE_NAME"
    else
        echo "⚠️  Login process completed, but credential verification failed."
        echo "This could be because you need to select an account and role in the browser."
        echo ""
        echo "Please try using the profile with a simple AWS command:"
        echo "aws s3 ls --profile $PROFILE_NAME"
        echo ""
        echo "If that fails, you may need to manually log in using the AWS Console."
    fi
else
    echo "❌ SSO login process failed."
    echo "Please check your SSO configuration and try again."
    exit 1
fi
