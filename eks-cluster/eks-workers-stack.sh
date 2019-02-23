#!/bin/bash

source ./set-cluster.sh

# Number of  eks workers
NUM_WORKERS=2

#Customize stack name as needed
STACK_NAME=$EKS_CLUSTER-workers

NODE_GROUP=ng1

# EC2 AMI for EKS worker nodes with GPU support 
# see https://docs.aws.amazon.com/eks/latest/userguide/gpu-ami.html for AMI in selected AWS region
AMI_ID=

# cloud formationn template url
# see https://docs.aws.amazon.com/eks/latest/userguide/gpu-ami.html 
# for latest AWS CloudFormation worker node template.
CFN_URL=

# EC2 instance type
INSTANCE_TYPE=p3.16xlarge

# EC2 key pair name
KEY_NAME=saga

# VPC ID 
VPC_ID=`aws eks --region $AWS_REGION describe-cluster --name $EKS_CLUSTER | grep vpcId | awk '{print $2}' | sed 's/,//g'`
echo "Using VpcId: $VPC_ID"

# Customize Subnet ID
# This picks the first of multiple subnets in VPC. You may want to set a subnet explicitly. 
# The objective is to have the workers in the same subnet to minimize latency 
SUBNETS=`aws eks --region $AWS_REGION  describe-cluster --name $EKS_CLUSTER | grep subnet- | sed 's/\"//g'| sed ':a;N;$!ba;s/\n//g' | sed 's/ //g' | head -1 | sed 's/\s*,\s*/,/g' | cut -d ',' -f1`
echo "Using Subnets: $SUBNETS"


# Use only single cluster control plane security group
CONTROL_SG=`aws eks --region $AWS_REGION  describe-cluster --name $EKS_CLUSTER | grep sg- | sed 's/ //g'`
echo "Using Cluster control security group: $CONTROL_SG"

VOLUME_SIZE=200

aws cloudformation create-stack --region $AWS_REGION  --stack-name $STACK_NAME \
--template-url $CFN_URL \
--capabilities CAPABILITY_NAMED_IAM \
--parameters \
ParameterKey=ClusterName,ParameterValue=$EKS_CLUSTER \
ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=$CONTROL_SG \
ParameterKey=NodeGroupName,ParameterValue=$NODE_GROUP \
ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=$NUM_WORKERS \
ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=$NUM_WORKERS \
ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$NUM_WORKERS \
ParameterKey=NodeInstanceType,ParameterValue=$INSTANCE_TYPE \
ParameterKey=NodeImageId,ParameterValue=$AMI_ID \
ParameterKey=NodeVolumeSize,ParameterValue=$VOLUME_SIZE \
ParameterKey=KeyName,ParameterValue=$KEY_NAME \
ParameterKey=VpcId,ParameterValue=$VPC_ID \
ParameterKey=Subnets,ParameterValue=$SUBNETS
