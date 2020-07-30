#!/bin/bash

exist=`aws cloudformation list-stacks --stack-status-filter CREATE_IN_PROGRESS CREATE_COMPLETE ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE DELETE_IN_PROGRESS DELETE_FAILED UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_COMPLETE REVIEW_IN_PROGRESS --query "StackSummaries[*].StackName" | grep "project2"`

if [ ! -z "$exist" ] ; then
echo "delete exist stacks"
aws cloudformation delete-stack --stack-name project2-network
aws cloudformation delete-stack --stack-name project2-lb
fi

while [ ! -z "$exist" ]; do
echo "deleting exist stacks"
sleep 60s
exist=`aws cloudformation list-stacks --stack-status-filter CREATE_IN_PROGRESS CREATE_COMPLETE ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE DELETE_IN_PROGRESS DELETE_FAILED UPDATE_IN_PROGRESS UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_ROLLBACK_COMPLETE REVIEW_IN_PROGRESS --query "StackSummaries[*].StackName" | grep "project2"`
done

aws cloudformation create-stack \
--stack-name project2-network  \
--template-body file://project2-network.yml \
--parameters file://project2-network-params.json \
--capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
--region=us-west-2

network=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE ROLLBACK_COMPLETE UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE --query "StackSummaries[*].StackName" | grep "project2" | grep "network"`

while [ -z "$network" ]; do
echo "waiting for network to be ready"
sleep 60s
network=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE ROLLBACK_COMPLETE UPDATE_COMPLETE_CLEANUP_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE --query "StackSummaries[*].StackName" | grep "project2" | grep "network"`

done

aws cloudformation create-stack \
--stack-name project2-lb  \
--template-body file://project2-lb.yml \
--parameters file://project2-lb-params.json \
--capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM" \
--region=us-west-2

lb=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[*].StackName" | grep "project2" | grep "lb"`

while [  -z "$lb" ]; do
echo "waiting for lb to be ready"
sleep 60s
lb=`aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[*].StackName" | grep "project2" | grep "lb"`

done

aws cloudformation describe-stacks --stack-name project2-lb | jq ".Stacks" | jq -r '.[].Outputs[].OutputValue' | grep http