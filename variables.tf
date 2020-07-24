variable "region" {
    #default = "us-east-1"
}

variable "availability_zone1" {
    #default = "us-east-1a"
}

variable "availability_zone2" {
    #default = "us-east-1b"
}

variable "availability_zone3" {
    #default = "us-east-1c"
}

variable "subnet_group_name" {
    #default = "rds_group"
}

variable "key_pair_name" {
    default = "csye6225_su2020_keypair"
}

variable "key_id" {
    #default = "AKIAILFUTXMSFJEUERVQ"
    #default = "AKIAIGJDIIDOLZX56DJQ"
}

variable "secret" {
    #default = "JEyKU7sqoEJlTc2v+8kGeRgggmTsgeI+QgEfg+Gg"
    #default = "lxXw3FGZBLHrUw5o/hbED0jixnBYDdE+wx1gyjWM"
}

variable "s3_endpoint_prefix" {
    default = "https://s3"
}

variable "s3_endpoint_postfix" {
    default = "amazonaws.com"
}

variable "amiId" {
    #default = "ami-09a35531ae08a02d9"
}

variable "recordName" {
    default = "prod.snehalpatel.me."
}

variable "fromEmailAddress" {
    default = "donotreply@prod.snehalpatel.me"
}

variable "topic_arn" {
    default = "arn:aws:sns:us-east-1:262619488074:ForgotPasswordTopic"
}
