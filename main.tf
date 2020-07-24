provider "aws" {
  region = var.region
}

# Creating VPC
resource "aws_vpc" "csye6225_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name = "csye6225_vpc"
  }
}

# Creating Internet Gateway and attaching it to VPC
resource "aws_internet_gateway" "csye6225_gateway" {
    vpc_id = "${aws_vpc.csye6225_vpc.id}"
}

# Creating subnet1 in VPC
resource "aws_subnet" "csye6225_subnet1" {
  cidr_block = "10.0.0.0/24"
  vpc_id = "${aws_vpc.csye6225_vpc.id}"
  availability_zone = var.availability_zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_subnet_1"
  }
}

# Creating subnet2 in VPC
resource "aws_subnet" "csye6225_subnet2" {
  cidr_block = "10.0.1.0/24"
  vpc_id = "${aws_vpc.csye6225_vpc.id}"
  availability_zone = var.availability_zone2
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_subnet_2"
  }
}

# Creating subnet3 in VPC
resource "aws_subnet" "csye6225_subnet3" {
  cidr_block = "10.0.2.0/24"
  vpc_id = "${aws_vpc.csye6225_vpc.id}"
  availability_zone = var.availability_zone3
  map_public_ip_on_launch = true

  tags = {
    Name = "csye6225_subnet_3"
  }
}

# Creating routing table
resource "aws_route_table" "csye6225_route_table" {
    vpc_id = "${aws_vpc.csye6225_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.csye6225_gateway.id}"
    }
}

# Attaching subnet1 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet1" {
  subnet_id      = aws_subnet.csye6225_subnet1.id
  route_table_id = aws_route_table.csye6225_route_table.id
}

# Attaching subnet2 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet2" {
  subnet_id      = aws_subnet.csye6225_subnet2.id
  route_table_id = aws_route_table.csye6225_route_table.id
}

# Attaching subnet3 to route table
resource "aws_route_table_association" "csye6225_route_table_subnet3" {
  subnet_id      = aws_subnet.csye6225_subnet3.id
  route_table_id = aws_route_table.csye6225_route_table.id
}

# Declaring security group for alb on ports 80, 443
resource "aws_security_group" "alb" {
  name        = "alb_security_group"
  description = "Allow TLS inbound traffic on port 80, 443"
  vpc_id      = "${aws_vpc.csye6225_vpc.id}"

  ingress {
    description = "TLS from VPC on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC on port 443"
    from_port   = 443
    to_port     = 443
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
    Name = "alb_security_group"
  }
}

# Declaring security group for application on ports 22,3000,8080
resource "aws_security_group" "application" {
  name        = "app_security_group"
  description = "Allow TLS inbound traffic on ports 22,3000,8080"
  vpc_id      = "${aws_vpc.csye6225_vpc.id}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NodeJS Server"
    security_groups =  ["${aws_security_group.alb.id}"]
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
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
  vpc_id      = "${aws_vpc.csye6225_vpc.id}"

  ingress {
    description = "TLS from VPC on port 3306"
    security_groups =  ["${aws_security_group.application.id}"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
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
    rds_endpoint   = "${aws_db_instance.rds_instance.address}"
    access_key_id  = var.key_id
    secret_key     = var.secret
    s3_endpoint    = "${var.s3_endpoint_prefix}.${var.region}.${var.s3_endpoint_postfix}"
    region         = var.region
    topicArn       = var.topic_arn
    domainName     = var.recordName
  }
}

#Defining Launch Configuration for autoscaling
resource "aws_launch_configuration" "asg_launch_config" {
  name                        = "asg_launch_config"
  image_id                    = var.amiId
  instance_type               = "t2.medium"
  key_name                    = var.key_pair_name
  associate_public_ip_address = true
  user_data                   = "${data.template_file.init.rendered}"
  iam_instance_profile        = "${aws_iam_instance_profile.EC2Profile.name}"
  security_groups             = ["${aws_security_group.application.id}"]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Defining autoscaling group
resource "aws_autoscaling_group" "app_autoscaling_group" {
  name                 = "app_autoscaling_group"
  vpc_zone_identifier  = ["${aws_subnet.csye6225_subnet1.id}", "${aws_subnet.csye6225_subnet2.id}", "${aws_subnet.csye6225_subnet3.id}"]
  default_cooldown     = 60
  launch_configuration = "${aws_launch_configuration.asg_launch_config.name}"
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  target_group_arns    = ["${aws_lb_target_group.lb_target_port.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
      key                 = "Name"
      value               = "MyWebAppInstance"
      propagate_at_launch = true
  }
}

#Defining application load balancer
resource "aws_lb" "app_load_balancer" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb.id}"]
  subnets            = ["${aws_subnet.csye6225_subnet1.id}", "${aws_subnet.csye6225_subnet2.id}", "${aws_subnet.csye6225_subnet3.id}"]

  enable_deletion_protection = false

  tags = {
    Name = "app_load_balancer"
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = "${aws_lb.app_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.lb_target_port.arn}"
  }
}

#Defining port for load balancer to accept traffic for instances
resource "aws_lb_target_group" "lb_target_port" {
  name        = "lb-target-port"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_vpc.csye6225_vpc.id}"
}

#Creating resource aws_route53_zone to import and map hosted zone locally
resource "aws_route53_zone" "primary" {
    name = var.recordName
}

#Creating alias record for load balancer
resource "aws_route53_record" "alias_route53_record" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name    = var.recordName
  type    = "A"

  alias {
    name                   = "${aws_lb.app_load_balancer.dns_name}"
    zone_id                = "${aws_lb.app_load_balancer.zone_id}"
    evaluate_target_health = true
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
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    Name = "csye6225-dynamodb-table"
  }
}

#Creating CodeDeploy Application Resource for Webapp
resource "aws_codedeploy_app" "csye6225-webapp" {
  name = "csye6225-webapp"
  compute_platform = "Server"
}

#Creating CodeDeploy Deployment Group Resource for Webapp
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name = aws_codedeploy_app.csye6225-webapp.name
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn = aws_iam_role.CodeDeployServiceRole.arn
  autoscaling_groups = ["${aws_autoscaling_group.app_autoscaling_group.name}"]
  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type = "IN_PLACE"
  }

  ec2_tag_filter {
    type = "KEY_AND_VALUE"
    key = "Name"
    value = "MyWebAppInstance"
  }
}

#Creating CodeDeploy Application Resource for Webapp-UI
resource "aws_codedeploy_app" "csye6225-webapp-ui" {
  name = "csye6225-webapp-ui"
  compute_platform = "Server"
}

#Creating CodeDeploy Deployment Group Resource for Webapp-UI
resource "aws_codedeploy_deployment_group" "csye6225-webapp-ui-deployment" {
  app_name = aws_codedeploy_app.csye6225-webapp-ui.name
  deployment_group_name = "csye6225-webapp-ui-deployment"
  service_role_arn = aws_iam_role.CodeDeployServiceRole.arn
  autoscaling_groups = ["${aws_autoscaling_group.app_autoscaling_group.name}"]
  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type = "IN_PLACE"
  }

  ec2_tag_filter {
    type = "KEY_AND_VALUE"
    key = "Name"
    value = "MyWebAppInstance"
  }
}

#Creating SNS Topic
resource "aws_sns_topic" "sns_topic" {
  name = "ForgotPasswordTopic"
}

#Defining Lambda Function
resource "aws_lambda_function" "lambda_function_sendemail" {
  filename         = "/home/snehal/faas-0.0.1-SNAPSHOT.jar"
  function_name    = "SendEmailOnSNS"
  role             = "${aws_iam_role.LambdaFunctionRole.arn}"
  handler          = "com.csye6225.faas.events.SendEmailEvent::handleRequest"
  runtime          = "java8"
  memory_size      = 512
  timeout          = 120


  environment {
    variables = {
      fromEmailAddress = var.fromEmailAddress
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  action        = "lambda:*"
  function_name = "${aws_lambda_function.lambda_function_sendemail.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "arn:aws:sns:us-east-1:262619488074:ForgotPasswordTopic"
}

#Creating SQS Queue
resource "aws_sqs_queue" "sqs_queue" {
  name = "ForgotPasswordQueue"
  tags = {
    Name = "ForgotPasswordQueue"
  }
}

#Creating the topic subscription
resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  topic_arn = aws_sns_topic.sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambda_function_sendemail.arn
}
