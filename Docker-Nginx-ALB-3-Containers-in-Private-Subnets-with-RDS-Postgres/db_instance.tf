resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "rds security group"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["1.2.3.4/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "rds_security_group"
  }
}

resource "aws_db_instance" "db" {
  engine            = "${var.rds_engine}"
  engine_version    = "${var.rds_engine_version}"
  identifier        = "${var.rds_identifier}"
  instance_class    = "${var.rds_instance_type}"
  allocated_storage = "${var.rds_storage_size}"
  name              = "${var.rds_db_name}"
  username          = "${var.rds_admin_user}"
  password          = "${var.rds_admin_password}"
  publicly_accessible    = "${var.rds_publicly_accessible}"
  vpc_security_group_ids = ["${aws_security_group.rds_security_group.id}"]
  tags {
    Name = "Postgres Database in ${var.aws_region}"
  }
}

output "postgress-address" {
  value = "address: ${aws_db_instance.db.address}"
}