#!/bin/bash


set -e
TOKEN_GITHUB=$ORG_GITHUB_TOKEN
repos=("")
datetime=$(date +"%Y-%m-%d")
BUCKET_NAME=""
ORG_NAME=""

if [ -z "$TOKEN_GITHUB" ]; then
    echo "Error: TOKEN_GITHUB environment variable is not set."
    exit 1
fi


# backup process
mkdir -p $ORG_NAME

for REPO in "${repos[@]}"; do
    echo "Cloning $REPO repository..."
    git clone "https://$TOKEN_GITHUB@github.com/$ORG_NAME/${REPO}" "$ORG_NAME/$REPO"
done
echo "Archiving repositories..."
tar -czf "$datetime.tar.gz" $ORG_NAME
echo "Uploading $datetime.tar.gz to S3..."
aws s3 cp "${datetime}.tar.gz" s3://$BUCKET_NAME/$ORG_NAME/"${datetime}.tar.gz"
echo "repositories backup completed."

