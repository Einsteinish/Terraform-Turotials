# security group for application load balancer
resource "aws_security_group" "docker_demo_alb_sg" {
  name        = "docker-nginx-demo-alb-sg"
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
  tags {
    Name = "alb-security-group-docker-demo"
  }
}

# using ALB - instances in private subnets
resource "aws_alb" "docker_demo_alb" {
  name                      = "docker-demo-alb"
  security_groups           = ["${aws_security_group.docker_demo_alb_sg.id}"]
  subnets                   = ["${aws_subnet.private.*.id}"]
  tags {
    Name = "docker-demo-alb"
  }
}

# alb target group
resource "aws_alb_target_group" "docker-demo-tg" {
  name     = "docker-demo-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo.id}"
  health_check {
    path = "/"
    port = 80
  }
}

# listener
resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = "${aws_alb.docker_demo_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.docker-demo-tg.arn}"
    type             = "forward"
  }
}

# target group attach
# using nested interpolation functions and the count parameter to the "aws_alb_target_group_attachment"
resource "aws_lb_target_group_attachment" "docker-demo" {
  count            = "${length(var.azs)}"
  target_group_arn = "${aws_alb_target_group.docker-demo-tg.arn}"
  target_id        =  "${element(split(",", join(",", aws_instance.docker_demo.*.id)), count.index)}"
  port             = 80
}

# ALB DNS is generated dynamically, return URL so that it can be used
output "url" {
  value = "http://${aws_alb.docker_demo_alb.dns_name}/"
}
