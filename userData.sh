#!/bin/bash
echo "RDS_URL=${rds_endpoint}" >> /etc/environment
echo "DB_USERNAME=csye6225" >> /etc/environment
echo "DB_PASSWORD=Password123" >> /etc/environment
echo "AWS_ACCESS_KEY_ID=${access_key_id}" >> /etc/environment
echo "AWS_SECRET_ACCESS_KEY=${secret_key}" >> /etc/environment
echo "BUCKET_NAME=webapp.snehal.patel" >> /etc/environment
echo "BUCKET_URL=${s3_endpoint}" >> /etc/environment
echo "AWS_REGION=${region}" >> /etc/environment
