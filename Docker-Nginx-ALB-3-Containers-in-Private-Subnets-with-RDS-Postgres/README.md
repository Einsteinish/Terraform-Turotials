# terraform-nginx-docker-containers-behind-a-ALB-with-private-subnets-instances-in-target-groups-with-RDS-Postgres

VPC with 3 AZs with a public/private for each AZs
 
3 containers in private subnets behind a Application Load Balancer (ALB) with RDS Postgres

A Terraform configuration to launch a cluster of EC2 instances.  Each EC2 instance runs a single nginx Docker container (based on the latest official nginx Docker image).  One EC2 instance is launched in each availability zone of the current region (see Regions below).  The load balancer and EC2 instances are launched in a **custom VPC**, and use custom security groups.

Applying the configuration takes about 30 seconds (in US West Oregon), and another two or three minutes for the EC2 instances to become healthy and for the load balancer DNS record to propagate.

## Files
+ `provider.tf` - AWS Provider.
+ `ec2.tf` - Launches EC2 instances, during initialization each instance installs Docker and the nginx Docker image.
+ `db_instance.tf` - Launches postgres rds instance
+ `elb.tf` - Launches elastic load balancer for EC2 instances running nginx.
+ `vars.tf` - Used by other files, sets default AWS region, calculates availability zones, etc.
+ `vars-rds-postgres.tf` - Used to setup postgres variables.
+ `vpc.tf` - Launches VPC, subnets, route tables, etc.

## Access credentials
AWS access credentials must be supplied on the command line (see example below).  This Terraform script was tested in my own AWS account with a user that has the `AmazonEC2FullAccess` and `AmazonVPCFullAccess` policies.  It was also tested in the Splice-supplied AWS account with a user that has the `AdministratorAccess` policy.

## Command Line Examples
To setup provisioner
```
$ terraform init
```

To launch the EC2 demo cluster:
```
$ terraform plan -out=aws.tfplan -var "aws_access_key=······" -var "aws_secret_key=······"
$ terraform apply aws.tfplan
```
To teardown the EC2 demo cluster:
```
$ terraform destroy -var "aws_access_key=······" -var "aws_secret_key=······"
```
Note: we can skip the keys args in the command if they are set via shell/env exported variables.

## Regions
The default AWS region is US East Virginia (us-east-1).  However, we can specify an alternate US region on the command line by passing in an extra `aws_region` argument.  Legal values are `us-east-1`, `us-east-2`, `us-west-1`, and `us-west-2` (default).  For example:
```
$ terraform plan -out=aws.tfplan -var "aws_access_key=······" -var "aws_secret_key=······" -var "aws_region=us-east-2"
$ terraform apply aws.tfplan
$ terraform destroy -var "aws_access_key=······" -var "aws_secret_key=······" -var "aws_region=us-east-2"
```
Note: we can skip the keys args in the command if they are set via shell/env exported variables.

## Output - url & db address
Applying this Terraform configuration returns the load balancer's public URL on the last line of output.  This URL can be used to view the default nginx homepage. Also, the ouput provids rds address. So, the output should look like this:

postgress-address = address: db.cw005b9fmtrd.us-east-1.rds.amazonaws.com
url = http://docker-demo-alb-1424055070.us-east-1.elb.amazonaws.com/
