## AWS Account

Put github creds into .devcontainer/.env to auto load them into the devcontainer

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
			"Action": [
				"iam:*"
			],
			"Resource": "*"
		},
		{
			"Sid": "VisualEditor2",
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

Enter it when prompted when running `create_pipeline.sh`
Enter yes when you need to, and remember to run `destory_pipeline.sh` afterwards

If you want to ssh into the EC2 to debug, look at /var/log/cloud-init-output.log
Edit pipeline.tf to add more ports when needed

Troubleshooting:
- SSH into the pipeline EC2, cd to /opt/devops-final-project/devopspipeline
- docker-compose logs <service name, e.g. jenkins>

- If you don't see any jobs on the jenkins UI, it's probably because the jenkins scripts to initialize jobs failed
- It takes a while for jenkins to start





