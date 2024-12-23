#!/bin/bash

# Global variables
USER_ARN=""
ROLE=""
SESSION_NAME=""
AWS_ACCESS_KEY_ID=''
AWS_ACCESS_KEY_SECRET=''
AWS_REGION=''
SESSION_TIMEOUT=36000
# eks
CLUSTER=""

check_aws_command() {
    echo "Checking if AWS CLI is installed and functional..."
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI is not installed or not in the system's PATH."
        exit 1
    fi

    echo "Testing AWS CLI connectivity..."
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "AWS CLI is not able to authenticate. Please check your AWS configuration or credentials."
        exit 1
    fi

    echo "AWS CLI is working correctly."
}

unset_aws_credentials() {
    echo "Unsetting AWS credentials..."
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    echo "AWS credentials have been cleared."
}

aws_configure () {
    unset_aws_credentials
    echo "Configuring AWS CLI credentials..."
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile profile1
    aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET" --profile profile1
    aws configure set region "$AWS_REGION" --profile profile1
    aws configure set output "json" --profile profile1
}

assume_role () {
    echo "Assuming role $ROLE..."

    # Unset old credentials if they exist
    unset_aws_credentials

    # Assume the role
    ASSUME_OUTPUT=$(aws sts assume-role --role-arn "$ROLE" --role-session-name "$SESSION_NAME" --duration-seconds "$SESSION_TIMEOUT")

    if [ $? -eq 0 ]; then
        echo "Role assumed successfully, exporting credentials..."

        KEY_ID=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.AccessKeyId')
        KEY_SECRET=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.SecretAccessKey')
        TOKEN=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.SessionToken')

        export AWS_ACCESS_KEY_ID="$KEY_ID"
        export AWS_SECRET_ACCESS_KEY="$KEY_SECRET"
        export AWS_SESSION_TOKEN="$TOKEN"
        export SESSION_EXPIRATION=$(echo "$ASSUME_OUTPUT" | jq -r '.Credentials.Expiration')

        echo "Credentials exported successfully. Session valid until: $SESSION_EXPIRATION"
    else
        echo "Failed to assume role."
        exit 1
    fi
}

check_session_expiration() {
    CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$CURRENT_TIME" > "$SESSION_EXPIRATION" ]]; then
        echo "Session has expired or is about to expire."
        assume_role
    else
        echo "Session is still valid until: $SESSION_EXPIRATION"
    fi
}

check_role () {
    echo "Checking if role is set..."

    IDENTITY=$(aws sts get-caller-identity --query "Arn" --output text)

    if [[ "$IDENTITY" == "$USER_ARN" ]]; then
        echo "Your current identity is $USER_ARN"
        echo "Switching to role $ROLE"
        assume_role
    else
        echo "Identity mismatch or role not set. Current identity: $IDENTITY"
    fi

    # Re-check after assuming role
    ID_RESULT=$(aws sts get-caller-identity --query "Arn" --output text)
    if [[ "$ID_RESULT" == *"$ROLE"* ]]; then
        echo "Role successfully assumed: $ID_RESULT"
    else
        echo "Role assumption failed or mismatch."
        exit 1
    fi
}

# Function to check session expiration or reconfigure and assume role if needed
check_or_reconfigure_session() {
    if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" || -z "$AWS_SESSION_TOKEN" ]]; then
        echo "No session detected, assuming role..."
        assume_role
    else
        echo "Checking session expiration..."
        check_session_expiration
    fi
}
eks_update() {
    if [ -z "$CLUSTER" ]; then
        echo "Error: CLUSTER variable is not set. Cannot update EKS configuration."
        return 1  # Return error code
    fi

    echo "Checking if EKS cluster configuration needs to be updated..."
    aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Updating EKS cluster kubeconfig..."
        aws eks --region "$AWS_REGION" update-kubeconfig --name "$CLUSTER"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to update EKS kubeconfig."
            return 1 # Return error code
        else
            echo "EKS kubeconfig updated successfully."
            return 0
        fi
    else
        echo "EKS cluster kubeconfig is already up-to-date."
        return 0
    fi
}

eks_interactive_configure() {
    if [ -t 0 ]; then  # Check if running in a terminal
        if [ -z "$CLUSTER" ]; then
            read -r -p "Enter the EKS cluster name: " CLUSTER
            if [ -z "$CLUSTER" ]; then
                echo "Error: EKS cluster name cannot be empty."
                return 1 # Return error code
            fi
        fi

        read -r -p "Do you want to configure the EKS cluster? (y/n): " response
        case "$response" in
            [yY]|[yY][eE][sS])  # More robust matching
                echo "Starting EKS configuration..."
                if eks_update; then # Check the return code of eks_update
                    echo "EKS configuration completed."
                else
                    echo "EKS configuration failed."
                fi
                ;;
            [nN]|[nN][oO])
                echo "Skipping EKS configuration."
                ;;
            *)
                echo "Invalid input. Skipping EKS configuration."
                ;;
        esac
    else
        echo "Script is running in the background. Skipping EKS configuration."
    fi
}

check_aws_command
check_or_reconfigure_session
check_role
eks_interactive_configure