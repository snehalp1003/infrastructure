provider "aws" {
  region = var.region
}

# Creating VPC
resource "aws_vpc" "csye6225_a4_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "csye6225_a4_vpc"
  }
}

# Creating Internet Gateway and attaching it to VPC
resource "aws_internet_gateway" "csye6225_a4_gateway" {
    vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
}

# Creating subnet1 in VPC
resource "aws_subnet" "csye6225_subnet1" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = var.availability_zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_1"
  }
}

# Creating subnet2 in VPC
resource "aws_subnet" "csye6225_subnet2" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = var.availability_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_2"
  }
}

# Creating subnet3 in VPC
resource "aws_subnet" "csye6225_subnet3" {
  cidr_block = "10.0.2.0/24"
  vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"
  availability_zone = var.availability_zone3
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_a4_subnet_3"
  }
}

# Creating routing table
resource "aws_route_table" "csye6225_a4_route_table" {
    vpc_id = "${aws_vpc.csye6225_a4_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.csye6225_a4_gateway.id}"
    }
}

# Attaching subnet1 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet1" {
  subnet_id      = aws_subnet.csye6225_subnet1.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}

# Attaching subnet2 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet2" {
  subnet_id      = aws_subnet.csye6225_subnet2.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}

# Attaching subnet3 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet3" {
  subnet_id      = aws_subnet.csye6225_subnet3.id
  route_table_id = aws_route_table.csye6225_a4_route_table.id
}

# Declaring security group for application on ports 443,22,80,3000,8080
resource "aws_security_group" "application" {
  name        = "app_security_group"
  description = "Allow TLS inbound traffic on ports 443,22,80,3000,8080"
  vpc_id      = "${aws_vpc.csye6225_a4_vpc.id}"

  ingress {
    description = "TLS from VPC on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodeJS Server"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP-Tomcat"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app_security_group"
  }
}

# Declaring security group for database on ports 3306
resource "aws_security_group" "database" {
  name        = "db_security_group"
  description = "Allow TLS inbound traffic on port 3306"
  vpc_id      = "${aws_vpc.csye6225_a4_vpc.id}"

  ingress {
    description = "TLS from VPC on port 3306"
    security_groups =  ["${aws_security_group.application.id}"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.csye6225_a4_vpc.cidr_block]
  }

  tags = {
    Name = "db_security_group"
  }
}

# Creating private S3 bucket with default encryption & lifecycle policy
resource "aws_s3_bucket" "webapp_bucket" {
  bucket = "webapp.snehal.patel"
  acl    = "private"
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "${aws_kms_key.key_for_encryption.arn}"
      sse_algorithm     = "aws:kms"
    }
  }
}

  lifecycle_rule {
    enabled = true
    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
  }

  tags = {
    Name = "webapp_bucket"
  }
}

# Key to encrypt bucket objects
resource "aws_kms_key" "key_for_encryption" {
  description             = "Key to encrypt bucket objects"
  deletion_window_in_days = 10
}

# Creating db_subnet_group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = var.subnet_group_name
  subnet_ids = ["${aws_subnet.csye6225_subnet1.id}", "${aws_subnet.csye6225_subnet2.id}", "${aws_subnet.csye6225_subnet3.id}"]

  tags = {
    Name = "My RDS subnet group"
  }
}

# Creating RDS instance
resource "aws_db_instance" "rds_instance" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "csye6225"
  username             = "csye6225"
  password             = "Password123"
  parameter_group_name = "default.mysql5.7"
  multi_az             = false
  publicly_accessible  = false
  identifier           = "csye6225-su2020"
  vpc_security_group_ids = ["${aws_security_group.database.id}"]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  skip_final_snapshot  = true
}

# Initializing userData
data "template_file" "init" {
  template = "${file("./userData.sh")}"
  vars = {
    rds_endpoint  = "${aws_db_instance.rds_instance.address}"
    access_key_id = var.key_id
    secret_key    = var.secret
    s3_endpoint   = "${var.s3_endpoint_prefix}.${var.region}.${var.s3_endpoint_postfix}"
    region        = var.region
  }
}

#Creating EC2 instance with custom AMI
resource "aws_instance" "MyWebAppInstance" {
  ami                  = var.amiId
  instance_type        = "t2.medium"
  key_name             = var.key_pair_name
  subnet_id            = "${aws_subnet.csye6225_subnet1.id}"
  iam_instance_profile = "${aws_iam_instance_profile.EC2Profile.name}"
  user_data            = "${data.template_file.init.rendered}"
  #availability_zone = var.availability_zone1

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }
  vpc_security_group_ids = ["${aws_security_group.application.id}"]

  tags = {
    Name = "MyWebAppInstance"
  }
}

#Create DynamoDB Table
resource "aws_dynamodb_table" "csye6225-dynamodb-table" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = false
  }

  tags = {
    Name = "csye6225-dynamodb-table"
  }
}

#Create EC2-CSYE6225 role
resource "aws_iam_role" "EC2-CSYE6225" {
  name = "EC2-CSYE6225"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

#Creating EC2 instance profile
resource "aws_iam_instance_profile" "EC2Profile" {
  name = "EC2Profile"
  role = "${aws_iam_role.EC2-CSYE6225.name}"
}

#Create WebAppS3 Policy and attching it to role EC2-CSYE6225
resource "aws_iam_role_policy" "WebAppS3" {
  name        = "WebAppS3"
  role        = "${aws_iam_role.EC2-CSYE6225.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::webapp.snehal.patel"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::webapp.snehal.patel/*"
            ]
        }
    ]
}
EOF
}
