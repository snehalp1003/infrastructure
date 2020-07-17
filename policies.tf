#Creating EC2 instance profile
resource "aws_iam_instance_profile" "EC2Profile" {
  name = "EC2Profile"
  role = "${aws_iam_role.EC2ServiceRole.name}"
}

#Create EC2ServiceRole role
resource "aws_iam_role" "EC2ServiceRole" {
  name = "EC2ServiceRole"

  assume_role_policy = data.aws_iam_policy_document.ec2-instance-assume-role-policy.json

  tags = {
    tag-key = "tag-value"
  }
}

#JSON for EC2 assume_role_policy
data "aws_iam_policy_document" "ec2-instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#Create WebAppS3 Policy
resource "aws_iam_policy" "WebAppS3" {
  name        = "WebAppS3"

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

#Attaching WebAppS3 policy to EC2ServiceRole role
resource "aws_iam_role_policy_attachment" "WebAppS3_EC2ServiceRole_attach" {
  policy_arn = "${aws_iam_policy.WebAppS3.arn}"
  role = "${aws_iam_role.EC2ServiceRole.name}"
}

###################################################################################################

#Create CodeDeploy-EC2-S3 Policy
#This policy will allow EC2 instances to read from S3.
resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.snehalpatel.me",
                "arn:aws:s3:::codedeploy.snehalpatel.me/*"
            ]
        }
    ]
}
EOF
}

#Attaching CodeDeploy-EC2-S3 policy to EC2ServiceRole role
resource "aws_iam_role_policy_attachment" "CodeDeploy-EC2-S3_EC2ServiceRole_attach" {
  policy_arn = "${aws_iam_policy.CodeDeploy-EC2-S3.arn}"
  role = "${aws_iam_role.EC2ServiceRole.name}"
}

#Attaching CloudWatchAgentServerPolicy policy to EC2ServiceRole role
resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role = "${aws_iam_role.EC2ServiceRole.name}"
}

###################################################################################################

#Creating resource aws_iam_user to import and map IAM user cicd locally
resource "aws_iam_user" "cicd" {
    name = "cicd"
}

#Create CircleCI-Upload-To-S3 Policy
#This policy allows CircleCI to upload artifacts from latest successful build to dedicated S3 bucket used by CodeDeploy.
resource "aws_iam_policy" "CircleCI-Upload-To-S3" {
  name        = "CircleCI-Upload-To-S3"

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
                "arn:aws:s3:::codedeploy.snehalpatel.me"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::codedeploy.snehalpatel.me/*"
            ]
        }
    ]
}
EOF
}

#Attaching CircleCI-Upload-To-S3 policy to cicd user
resource "aws_iam_user_policy_attachment" "CircleCI-Upload-To-S3_cicd_attach" {
  user       = "${aws_iam_user.cicd.name}"
  policy_arn = "${aws_iam_policy.CircleCI-Upload-To-S3.arn}"
}

#Create CircleCI-Code-Deploy Policy
#This policy allows CircleCI to call CodeDeploy APIs to initiate application deployment on EC2 instances.
resource "aws_iam_policy" "CircleCI-Code-Deploy" {
  name        = "CircleCI-Code-Deploy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codedeploy:CreateDeployment",
                "codedeploy:GetApplicationRevision",
                "codedeploy:RegisterApplicationRevision",
                "codedeploy:GetDeploymentConfig",
                "codedeploy:GetDeployment"
            ],
            "Resource": [
                "arn:aws:codedeploy:us-east-1:262619488074:deploymentconfig:CodeDeployDefault.AllAtOnce",
                "arn:aws:codedeploy:us-east-1:262619488074:application:*",
                "arn:aws:codedeploy:us-east-1:262619488074:deploymentgroup:*/*"
            ]
        }
    ]
}
EOF
}


#Attaching CircleCI-Code-Deploy policy to cicd user
resource "aws_iam_user_policy_attachment" "CircleCI-Code-Deploy_cicd_attach" {
  user       = "${aws_iam_user.cicd.name}"
  policy_arn = "${aws_iam_policy.CircleCI-Code-Deploy.arn}"
}

#Create circleci-ec2-ami Policy
#This policy is for Packer to use credentials provided by instance's IAM role
resource "aws_iam_policy" "circleci-ec2-ami" {
  name        = "circleci-ec2-ami"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":  [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#Attaching circleci-ec2-ami policy to cicd user
resource "aws_iam_user_policy_attachment" "circleci-ec2-ami_cicd_attach" {
  user       = "${aws_iam_user.cicd.name}"
  policy_arn = "${aws_iam_policy.circleci-ec2-ami.arn}"
}

###################################################################################################

#Creating IAM Role for CodeDeploy Service
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"
  assume_role_policy = data.aws_iam_policy_document.codedeploy-assume-role-policy.json
}

#Creating policy document for CodeDeploy Service
data "aws_iam_policy_document" "codedeploy-assume-role-policy" {
 statement {
   actions = ["sts:AssumeRole"]

   principals {
     type        = "Service"
     identifiers = ["codedeploy.amazonaws.com"]
   }
 }
}

#Attaching AWSCodeDeployRole permission to CodeDeployServiceRole
resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role = "${aws_iam_role.CodeDeployServiceRole.name}"
}

###################################################################################################
#This section defines the policies for autoscaling and their respective cloudwatch metric alarms

#This is scale up policy
resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.app_autoscaling_group.name}"
}

#This is scale down policy
resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = "${aws_autoscaling_group.app_autoscaling_group.name}"
}

#This metric alarm will trigger scale up policy
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name             = "CPUAlarmHigh"
  alarm_description      = "Scale-up if CPU > 5% for 1 minute"
  comparison_operator    = "GreaterThanThreshold"
  metric_name            = "CPUUtilization"
  namespace              = "AWS/EC2"
  statistic              = "Average"
  period                 = "300"
  evaluation_periods     = "1"
  threshold              = "5"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.app_autoscaling_group.name}"
  }
  alarm_actions          = ["${aws_autoscaling_policy.WebServerScaleUpPolicy.arn}"]
}

#This metric alarm will trigger scale down policy
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name             = "CPUAlarmLow"
  alarm_description      = "Scale-down if CPU < 3% for 1 minute"
  comparison_operator    = "LessThanThreshold"
  metric_name            = "CPUUtilization"
  namespace              = "AWS/EC2"
  statistic              = "Average"
  period                 = "300"
  evaluation_periods     = "1"
  threshold              = "3"

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.app_autoscaling_group.name}"
  }
  alarm_actions          = ["${aws_autoscaling_policy.WebServerScaleDownPolicy.arn}"]
}
