from ebs_utils import create_ebs_volume

def main():
    REGION_NAME = ''  # AWS region
    AVAILABILITY_ZONE = ''  # Availability zone in the region
    SIZE = 10  # Size of the volume in GiB
    VOLUME_TYPE = 'gp3'  # Volume type (e.g., gp2, io1, st1)
    ENCRYPT = True
    NAME = 'my-volume-data'

    volume_id = create_ebs_volume(REGION_NAME, AVAILABILITY_ZONE, SIZE, VOLUME_TYPE, ENCRYPT, NAME)
    print(f"The volume ID returned: {volume_id}")

if __name__ == "__main__":
    main()