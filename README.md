# DEVOPS-challenge

Challenge : 
Write a terraform module and template to deploy the openmrs application in AWS .

After creating image with packer , run below steps with proper access key and secret key

Steps :
note: place .tf files in one folder before executing 

terraform validate .

terraform plan -var 'subnets=["subnet-b3c5d09d"]' -var  'vpc-id=vpc-bdefb4c7' -var 'LB-sg=sg-089ec31cff696597a' -var 'cpu-target=30' -var 'key-pair=monitoring' -var 'ami=ami-0739e0128c286a437' -var 'setid=prim' -var 'zoneid=Z06774451FDK1P5O1H9UZ' -var 'record-name=neelimaprim' -var 'failover-type=PRIMARY' -out='aws.plan' .

terraform apply "aws.plan"

terraform destroy -var 'subnets=["subnet-b3c5d09d"]' -var  'vpc-id=vpc-bdefb4c7' -var 'LB-sg=sg-089ec31cff696597a' -var 'cpu-target=30' -var 'key-pair=monitoring' -var 'ami=ami-0739e0128c286a437' -var 'setid=prim' -var 'zoneid=Z06774451FDK1P5O1H9UZ' -var 'record-name=neelimaprim' -var 'failover-type=PRIMARY'
