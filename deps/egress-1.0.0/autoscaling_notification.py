import boto3
import json
import os

def get_route_table_for_subnet(route_table):
    for association in route_table['Associations']:
        return association['SubnetId']

def get_az_for_subnet(subnets, subnet_id):
    for subnet in subnets:
        if subnet['SubnetId'] == subnet_id:
            return subnet['AvailabilityZone']

def get_instance_for_az(instances, az):
    # Try to find the most appropriate instance
    for instance in instances:
        if instance['Instances'][0]['Placement']['AvailabilityZone'] == az:
            return instance

    # Worst case: return the first one
    for instance in instances:
        return instance

def does_world_route_exist(route_table):
    for route in route_table['Routes']:
        if 'DestinationCidrBlock' in route and route['DestinationCidrBlock'] == '0.0.0.0/0':
            return True

    return False

def lambda_handler(event, context):
    client = boto3.client("ec2")

    asg_name = os.environ['AUTOSCALING_GROUP_NAME']
    vpc_id = os.environ['VPC_ID']

    ec2_instances = client.describe_instances(Filters=[
        {'Name': 'tag:aws:autoscaling:groupName', 'Values': [asg_name]},
        {'Name': 'instance-state-name', 'Values': ['running']},
    ])['Reservations']

    print("ec2_instances: ", ec2_instances)

    private_subnets = []
    for subnet in client.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])['Subnets']:
        if not subnet['MapPublicIpOnLaunch']:
            private_subnets.append(subnet)

    private_subnet_ids = [t['SubnetId'] for t in private_subnets]

    print("private subnet ids: ", private_subnet_ids)

    private_route_tables = client.describe_route_tables(Filters=[
        {'Name': 'association.subnet-id', 'Values': private_subnet_ids}
    ])['RouteTables']

    for private_route_table in private_route_tables:
        print("processing", private_route_table)
        route_table_subnet_id = get_route_table_for_subnet(private_route_table)
        az_for_subnet = get_az_for_subnet(private_subnets, route_table_subnet_id)
        instance_for_az = get_instance_for_az(ec2_instances, az_for_subnet)
        has_world_route = does_world_route_exist(private_route_table)

        print("route_table_subnet_id", route_table_subnet_id)
        print("az_for_subnet", az_for_subnet)
        print("instance_for_az", instance_for_az)
        print("has_world_route", has_world_route)

        if not has_world_route:
            print("Creating route")
            client.create_route(
                DestinationCidrBlock='0.0.0.0/0',
                RouteTableId=private_route_table['RouteTableId'],
                InstanceId=instance_for_az['Instances'][0]['InstanceId']
            )
        else:
            print("route exists")
            for route in private_route_table['Routes']:
                if 'DestinationCidrBlock' in route \
                        and route['DestinationCidrBlock'] == '0.0.0.0/0' and route['State'] == 'blackhole':
                    print("Route already exist, but it's a blackhole")

                    client.replace_route(
                        DestinationCidrBlock='0.0.0.0/0',
                        RouteTableId=private_route_table['RouteTableId'],
                        InstanceId=instance_for_az['Instances'][0]['InstanceId']
                    )
                    break





test = False
if test:
    os.environ['AUTOSCALING_GROUP_NAME'] = "egress-autoscaling-group"
    os.environ['VPC_ID'] = "vpc-08b0c5fdde80d7cd0"
    lambda_handler(None, None)
