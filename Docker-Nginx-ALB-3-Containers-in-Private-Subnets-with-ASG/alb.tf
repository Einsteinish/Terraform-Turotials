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

# listener
resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.docker_demo_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.docker_demo_alb_tg.arn}"
    type             = "forward"
  }
}

#resource "aws_alb_listener_rule" "listener_rule" {
#  depends_on   = ["aws_alb_target_group.docker_demo_alb_tg"]  
#  listener_arn = "${aws_alb_listener.alb_listener.arn}"  
#  priority     = "${var.priority}"   
#  action {    
#    type             = "forward"    
#    target_group_arn = "${aws_alb_target_group.docker_demo_alb_tg.id}"  
#  }   
#  condition {    
#    field  = "path-pattern"    
#    values = ["${var.alb_path}"]  
#  }
#}

# alb target group
resource "aws_alb_target_group" "docker_demo_alb_tg" {
  name     = "docker-demo-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo.id}"
  health_check {
    path = "/"
    port = 80
  }
}


# target group attach - instance attachment
# using nested interpolation functions and the count parameter to the "aws_alb_target_group_attachment"
#resource "aws_alb_target_group_attachment" "alb_tg_attachment" {
#  count            = "${length(var.azs)}"
#  target_group_arn = "${aws_alb_target_group.docker_demo_alb_tg.arn}"
#  target_id        =  "${element(split(",", join(",", aws_instance.docker_demo.*.id)), count.index)}"
#  port             = 80
#}

# creating launch configuration
resource "aws_launch_configuration" "demo" {
  image_id               = "${lookup(var.ec2_amis, var.aws_region)}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.docker_demo_ec2.id}"]
  user_data              = "${file("user_data.sh")}"
  lifecycle {
    create_before_destroy = true
  }
}


# aws_autoscaling_group resource takes a target_group_arns parameter that will register the ASG 
# with the target group so that all instances are registered with the load balancer's target group 
# as they come up and properly drained from the load balancer before being terminated.

# creating autoscaling group
resource "aws_autoscaling_group" "docker_demo_asg" {
  name                        = "docker-demo-autoscaling-group"
  launch_configuration = "${aws_launch_configuration.demo.id}"
  #count                   = "${length(var.azs)}"
  #availability_zones       = "${element(var.azs,count.index)}"

  #vpc_zone_identifier = ["${element(aws_subnet.private.*.id, count.index)}"]
  #load_balancers = ["${aws_alb.docker_demo_alb.name}"]

  #availability_zones       = "[${var.azs.*}]"
  vpc_zone_identifier       = ["${aws_subnet.private.*.id}"]

  desired_capacity = 3
  max_size = 6
  min_size = 1

  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "docker-demo-asg"
    propagate_at_launch = true
  }
}

# autoscaling attachment  
resource "aws_autoscaling_attachment" "demo_asg_attachment" { 
  alb_target_group_arn   = "${aws_alb_target_group.docker_demo_alb_tg.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.docker_demo_asg.id}"
}


# ALB DNS is generated dynamically, return URL so that it can be used
output "url" {
  value = "http://${aws_alb.docker_demo_alb.dns_name}/"
}
