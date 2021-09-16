# AWS Details
Default region that are using in this project is - `us-east-1`

# Dependencies
- Terraform 1.0.6 ([Linux link](https://releases.hashicorp.com/terraform/1.0.6/terraform_1.0.6_linux_amd64.zip))

# Initial provisioning
1. Make sure you are in `remote/` folder right now (check with `pwd`).
2. Build provisioning container using following command: 
    ```
    docker build ./provision/ -t sm-infra-provisioner
    ```
3. Run above container with name of a unique state bucket name, for example: 
    ```
    docker run -it -v $(pwd)/infrastructure:/var/tf sm-infra-provisioner --state-bucket sm-state-bucket-dev
    ```
4. Run `terraform init` and `terraform apply`

# Lambda testing
https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-using-invoke.html

https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install-linux.html

https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip

## IAM Requirements

Example caller user permissions:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ApiGateway",
            "Effect": "Allow",
            "Action": [
                "apigateway:DELETE",
                "apigateway:PUT",
                "apigateway:PATCH",
                "apigateway:POST",
                "apigateway:GET"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Global",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VPC",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpc",
                "ec2:CreateTags",
                "ec2:DescribeTags",
                "ec2:DescribeVpc*",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:AssignPrivateIpAddresses",
                "ec2:UnassignPrivateIpAddresses",
                "ec2:DeleteVpc",
                "ec2:DescribeNetwork*",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeRouteTables",
                "ec2:DescribeSubnets",
                "ec2:CreateSecurityGroup",
                "ec2:RevokeSecurityGroup*",
                "ec2:DeleteSecurityGroup",
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAM",
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:ListInstanceProfilesForRole",
                "iam:ListAttachedRolePolicies",
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:ListRolePolicies",
                "iam:PassRole",
                "iam:UpdateAssumeRolePolicy",
                "iam:AttachRolePolicy"
            ],
            "Resource": [
                "arn:aws:iam::*:role/batch_lambda_iam_role",
                "arn:aws:iam::*:role/operational_lambda_iam_role"
            ]
        },
        {
            "Sid": "LambdaSpecific",
            "Effect": "Allow",
            "Action": "lambda:*",
            "Resource": [
                "arn:aws:lambda:*:*:function:sm-operator",
                "arn:aws:lambda:*:*:function:sm-process",
                "arn:aws:lambda:*:*:layer:sm_shared"
            ]
        },
        {
            "Sid": "LambdaGlobal",
            "Effect": "Allow",
            "Action": "lambda:CreateFunction",
            "Resource": "*"
        },
        {
            "Sid": "LambdaLayers",
            "Effect": "Allow",
            "Action": "lambda:*",
            "Resource": [
                "arn:aws:lambda:*:*:layer:sm_shared*"
            ]
        },
        {
            "Sid": "DebugMessages",
            "Effect": "Allow",
            "Action": "sts:DecodeAuthorizationMessage",
            "Resource": "*"
        },
        {
            "Sid": "DbLocalTest",
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "*"
        }
    ]
}
```