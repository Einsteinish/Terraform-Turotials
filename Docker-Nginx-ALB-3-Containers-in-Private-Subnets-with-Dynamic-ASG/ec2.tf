# security group for EC2 instances
resource "aws_security_group" "docker_demo_ec2" {
  name        = "docker-nginx-demo-ec2"
  description = "allow incoming HTTP traffic only"
  vpc_id      = "${aws_vpc.demo.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instances, one per availability zone
resource "aws_instance" "docker_demo" {
  ami                         = "${lookup(var.ec2_amis, var.aws_region)}"
  associate_public_ip_address = true
  count                       = "${length(var.azs)}"
  depends_on                  = ["aws_subnet.private"]
  instance_type               = "t2.micro"
  subnet_id                   = "${element(aws_subnet.private.*.id,count.index)}"
  user_data                   = "${file("user_data.sh")}"

  # references security group created above
  vpc_security_group_ids = ["${aws_security_group.docker_demo_ec2.id}"]

  tags {
    Name = "docker-nginx-demo-instance-${count.index}"
  }
}
