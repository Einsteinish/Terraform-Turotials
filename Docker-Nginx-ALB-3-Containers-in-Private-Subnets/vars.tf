# Put the following two keys into shell or env variables

#variable "aws_access_key" {
#  description = "AWS access key, must pass on command line using -var"
#}

#variable "aws_secret_key" {
#  description = "AWS secret access key, must pass on command line using -var"
#}

variable "aws_region" {
  description = "US EAST Virginia"
  default     = "us-east-1"
}

# dynamically retrieves all availability zones for current region
#data "aws_availability_zones" "available" {}

# specifying AZs 
#   comment off this "azs" to retrive all AZs dynamically (uncomment the line above "data ...")
variable "azs" {
  type = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ec2_amis" {
  description = "Ubuntu Server 16.04 LTS (HVM)"
  type        = "map"

  default = {
    "us-east-1" = "ami-059eeca93cf09eebd"
    "us-east-2" = "ami-0782e9ee97725263d"
    "us-west-1" = "ami-0ad16744583f21877"
    "us-west-2" = "ami-0e32ec5bc225539f5"
  }
}

variable "public_subnets_cidr" {
  type = "list"
  default = ["10.0.0.0/24", "10.0.2.0/24", "10.0.4.0/24"]
}

variable "private_subnets_cidr" {
  type = "list"
  default = ["10.0.1.0/24", "10.0.3.0/24", "10.0.5.0/24"]
}
