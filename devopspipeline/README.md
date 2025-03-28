## AWS Account

Create AWS account
Create IAM [DevOpsPipelineGroup] Group with [ECS+S3Access] policies:
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}

Create IAM User [DevOpsPipeline] under the role.
Create access key

Run `aws configure`
AWS Access Key ID [None]: <Your key ID>
AWS Secret Access Key [None]: <Your Key>
Default region name [None]: us-east-2
Default output format [None]: <I left it empty>


