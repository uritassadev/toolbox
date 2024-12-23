import boto3
import time


def list_ec2_instances(region_name):
    ec2 = boto3.resource('ec2', region_name=region_name)

    print(f"\nListing EC2 instances in region: {region_name}")

    instances = list(ec2.instances.all())
    if not instances:
        print("No instances found in this region.")
        return

    for instance in instances:
        instance_id = instance.id
        instance_name = 'N/A'
        ami_id = instance.image_id

        for tag in instance.tags or []:
            if tag['Key'] == 'Name':
                instance_name = tag['Value']
                break

        print(f"Instance ID: {instance_id}, Name: {instance_name}, AMI: {ami_id}")


def get_all_regions():
    ec2 = boto3.client('ec2')
    return [region['RegionName'] for region in ec2.describe_regions()['Regions']]


def list_instances_all_regions():
    regions = get_all_regions()

    for region in regions:
        try:
            list_ec2_instances(region)
        except Exception as e:
            print(f"Error listing instances in region {region}: {str(e)}")


# Run the function to list instances in all regions
list_instances_all_regions()

'''
create image from instance
'''


def create_image_from_instance(instance_id, image_name, image_description, tag_name):
    ec2 = boto3.client('ec2')

    # Create the image
    response = ec2.create_image(
        InstanceId=instance_id,
        Name=image_name,
        Description=image_description,
        NoReboot=True,  # Set to False if you want to stop the instance before imaging,
        TagSpecifications = [
            {
                'ResourceType': 'image',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': tag_name
                    }
                ]
            }
        ]
    )

    image_id = response['ImageId']
    print(f"Image creation started. Image ID: {image_id}")

    # Wait for the image to be available
    while True:
        image_info = ec2.describe_images(ImageIds=[image_id])['Images'][0]
        if image_info['State'] == 'available':
            print(f"Image {image_id} is now available")
            break
        elif image_info['State'] == 'failed':
            print(f"Image creation failed for {image_id}")
            break
        else:
            print(f"Image {image_id} is still being created. Current state: {image_info['State']}")
            time.sleep(30)  # Wait for 30 seconds before checking again

    return image_id


print()
print()

print("To create image from instance fill the details below ")
print()
instanceID = (input('Enter the instanceID: '))
imageName = (input('Enter the image name: '))
imageDescription = (input('Describe the instance: '))
tagName = input('Enter the tag value: ')
create_image_from_instance(instanceID, imageName, imageDescription, tagName)