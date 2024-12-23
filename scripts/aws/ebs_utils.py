import boto3

def create_ebs_volume(region_name, availability_zone, size, volume_type, encrypt, name):
    # Create an EC2 client
    ec2 = boto3.client('ec2', region_name=region_name)

    # Create the EBS volume
    response = ec2.create_volume(
        AvailabilityZone=availability_zone,
        Size=size,  # Size in GiB
        VolumeType=volume_type,
        Encrypted=encrypt,
        TagSpecifications=[
            {
                'ResourceType': 'volume',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': name
                    },
                ]
            },
        ],
    )

    # Get the Volume ID
    volume_id = response['VolumeId']
    print(f"Created EBS volume with ID: {volume_id}")

    return volume_id