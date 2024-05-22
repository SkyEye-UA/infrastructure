

resource "aws_security_group" "postgres_database_security_group" {
  name_prefix = "rds-database-security-group"
  vpc_id      = aws_vpc.sky_eye_vpc.id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = var.subnet_cidr_blocks
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "sky_eye_rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = aws_subnet.SkyEyeSubnets[*].id

  tags = {
    Name = "SkyEye subnet group"
  }
}

# Create an Amazon RDS PostgreSQL database
resource "aws_db_instance" "sky_eye_db_instance" {
  identifier             = var.db_instance_identifier
  db_name                = "sky_eye_db"
  engine                 = "postgres"
  engine_version         = "14"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  username               = var.db_instance_username
  password               = var.db_instance_password
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.postgres_database_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.sky_eye_rds_subnet_group.name
}