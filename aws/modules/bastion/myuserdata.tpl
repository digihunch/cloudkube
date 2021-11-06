#! /bin/bash
echo "Entering script myuserdata"
yum update -y

runuser -l ec2-user -c 'aws configure set region ${aws_region}'
echo "Leaving script myuserdata"
