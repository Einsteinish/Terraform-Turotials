# one vpc to hold them all, and in the cloud bind them
resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags {
    Name = "docker-nginx-demo-vpc"
  }
}

# let vpc talk to the internet - create internet gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.demo.id}"
  tags {
    Name = "docker-nginx-demo-igw"
  }
}

# create one public subnet per availability zone
resource "aws_subnet" "public" {
  availability_zone       = "${element(var.azs,count.index)}"
  cidr_block              = "${element(var.public_subnets_cidr,count.index)}"
  count                   = "${length(var.azs)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.demo.id}"
  tags {
    Name = "subnet-pub-${count.index}"
  }
}

# create one private subnet per availability zone
resource "aws_subnet" "private" {
  availability_zone       = "${element(var.azs,count.index)}"
  cidr_block              = "${element(var.private_subnets_cidr,count.index)}"
  count                   = "${length(var.azs)}"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.demo.id}"
  tags {
    Name = "subnet-priv-${count.index}"
  }
}

# dynamic list of the public subnets created above
data "aws_subnet_ids" "public" {
  depends_on = ["aws_subnet.public"]
  vpc_id     = "${aws_vpc.demo.id}"
}

# dynamic list of the private subnets created above
data "aws_subnet_ids" "private" {
  depends_on = ["aws_subnet.private"]
  vpc_id     = "${aws_vpc.demo.id}"
}

# main route table for vpc and subnets
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.demo.id}"
  tags {
    Name = "public_route_table_main"
  }
}

# add public gateway to the route table
resource "aws_route" "public" {
  gateway_id             = "${aws_internet_gateway.gw.id}"
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.public.id}"
}

# associate route table with vpc
resource "aws_main_route_table_association" "public" {
  vpc_id         = "${aws_vpc.demo.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# and associate route table with each subnet
resource "aws_route_table_association" "public" {
  count           = "${length(var.azs)}"
  subnet_id      = "${element(data.aws_subnet_ids.public.ids, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# create elastic IP (EIP) to assign it the NAT Gateway 
resource "aws_eip" "demo_eip" {
  count    = "${length(var.azs)}"
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}

# create NAT Gateways
# make sure to create the nat in a internet-facing subnet (public subnet)
resource "aws_nat_gateway" "demo" {
    count    = "${length(var.azs)}"
    allocation_id = "${element(aws_eip.demo_eip.*.id, count.index)}"
    subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
    depends_on = ["aws_internet_gateway.gw"]
}

# for each of the private ranges, create a "private" route table.
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.demo.id}"
  count ="${length(var.azs)}" 
  tags { 
    Name = "private_subnet_route_table_${count.index}"
  }
}

# add a nat gateway to each private subnet's route table
resource "aws_route" "private_nat_gateway_route" {
  count = "${length(var.azs)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  depends_on = ["aws_route_table.private"]
  nat_gateway_id = "${element(aws_nat_gateway.demo.*.id, count.index)}"
}

