# one vpc to hold them all, and in the cloud bind them
resource "aws_vpc" "public" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "Docker-Demo-VPC"
  }
}

# let vpc talk to the internet
resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.public.id}"

  tags {
    Name = "Docker-Demo-IGW"
  }
}

# create one subnet per availability zone
resource "aws_subnet" "public" {
  #availability_zone       = "${element(data.aws_availability_zones.available.names, count.index)}"
  availability_zone       = "${element(var.azs,count.index)}"
  cidr_block              = "10.0.${count.index}.0/24"
  #count                   = "${length(data.aws_availability_zones.available.names)}"
  count                   = "${length(var.azs)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.public.id}"
}

# dynamic list of the subnets created above
data "aws_subnet_ids" "public" {
  depends_on = ["aws_subnet.public"]
  vpc_id     = "${aws_vpc.public.id}"
}

# main route table for vpc and subnets
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.public.id}"

  tags {
    Name = "Docker-Public-Route-Table"
  }
}

# add public gateway to the route table
resource "aws_route" "public" {
  gateway_id             = "${aws_internet_gateway.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.public.id}"
}

# associate route table with vpc
resource "aws_main_route_table_association" "public" {
  vpc_id         = "${aws_vpc.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# and associate route table with each subnet
resource "aws_route_table_association" "public" {
  #count          = "${length(data.aws_availability_zones.available.names)}"
  count           = "${length(var.azs)}"
  subnet_id      = "${element(data.aws_subnet_ids.public.ids, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}



