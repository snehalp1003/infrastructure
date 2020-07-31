To run this project, execute the below commands:

1) terraform init
2) terraform validate
3) terraform plan
4) terraform apply

To destroy a network:

1) terraform destroy

To create a new network with the same template, run:

1) terraform workspace new <workspace_name>
2) terraform apply

To import your certificates to the AWS resource stack, run the below command:

 aws acm import-certificate --certificate file://Certificate.pem --certificate-chain file://CertificateChain.pem --private-key file://PrivateKey.pem
