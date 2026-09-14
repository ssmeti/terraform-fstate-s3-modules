#!/bin/bash
# verify_fifth_project.sh
# Cross-checks fifth-project's module-based VPC resources against real AWS,
# and against Terraform's own state.
# Usage: ./verify_fifth_project.sh

set -e

PROFILE="terraform-user"
PROJECT_NAME="fifth-project"

echo "=============================================="
echo "1. VPC"
echo "=============================================="
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" \
  --profile "$PROFILE" \
  --query "Vpcs[].{VpcId:VpcId,CIDR:CidrBlock,State:State}" \
  --output table

echo "=============================================="
echo "2. Internet Gateway"
echo "=============================================="
aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-igw" \
  --profile "$PROFILE" \
  --query "InternetGateways[].{IgwId:InternetGatewayId,Attachments:Attachments[0].State}" \
  --output table

echo "=============================================="
echo "3. Subnets"
echo "=============================================="
aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-*" \
  --profile "$PROFILE" \
  --query "Subnets[].{SubnetId:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table

echo "=============================================="
echo "4. Route Tables"
echo "=============================================="
aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=${PROJECT_NAME}-*" \
  --profile "$PROFILE" \
  --query "RouteTables[].{RtId:RouteTableId,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table

echo "=============================================="
echo "5. DB Subnet Group"
echo "=============================================="
aws rds describe-db-subnet-groups \
  --db-subnet-group-name "${PROJECT_NAME}-db-subnet-group" \
  --profile "$PROFILE" \
  --query "DBSubnetGroups[].{Name:DBSubnetGroupName,Status:SubnetGroupStatus,VpcId:VpcId}" \
  --output table 2>/dev/null || echo "DB subnet group not found."

echo "=============================================="
echo "6. Terraform state — module resource count"
echo "=============================================="
echo "Resources currently tracked by Terraform (should all be prefixed module.vpc.):"
terraform state list

echo ""
echo "Count of module.vpc.* resources in state:"
terraform state list | grep -c "^module.vpc\." || echo "0"

echo ""
echo "=============================================="
echo "7. Cross-check: any resource in state NOT under module.vpc.?"
echo "=============================================="
NON_MODULE=$(terraform state list | grep -v "^module.vpc\." || true)
if [ -z "$NON_MODULE" ]; then
  echo "None — every resource is correctly namespaced under the vpc module."
else
  echo "Found resources outside the module:"
  echo "$NON_MODULE"
fi

echo ""
echo "=============================================="
echo "8. terraform plan drift check (read-only, makes no changes)"
echo "=============================================="
terraform plan -detailed-exitcode > /tmp/fifth_project_plan.log 2>&1
PLAN_EXIT=$?
if [ "$PLAN_EXIT" -eq 0 ]; then
  echo "No drift — configuration matches real AWS state exactly."
elif [ "$PLAN_EXIT" -eq 2 ]; then
  echo "Drift detected — plan shows differences. Review with: terraform plan"
else
  echo "terraform plan failed — check /tmp/fifth_project_plan.log for details."
fi

echo ""
echo "Done."
