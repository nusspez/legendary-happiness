# WELCOME

## What does this repository?

this repository build a EC2 with nginx with a loadbalancer in port 8080 in AWS CDK and Terraform

## Epics

<details><summary>AWS CDK</summary>

<p>

### Prerequisites

- Python
- Npm
- Aws cli
- virtualenv

### how to run the aws CDK stack

Install aws CDK

```shell
   npm install aws-cdk-lib
```

Configure your aws stacks

```shell
    aws configure
```

Bootsraping your account

```shell
cdk bootstrap aws://ACCOUNT-NUMBER/REGION
```

Move to the directory

```shell
    cd CDK
```

Create the virtual env

```shell
    source .venv/bin/activate
```

Install the dependencies

```shell
    python -m pip install -r requirements.txt
```

change in app.py the next line

```shell
    env = cdk.Environment(account='', region='')
```

Run the stack

```shell
    cdk deploy --all --require-approval never
```

Erase all

```shell
    cdk destroy --all --force
```

</p>

</details>

<details><summary>Terraform</summary>

<p>

### Prerequisites

- Terraform
- AWS cli

### how to run the aws CDK stack

create the key pair
go to variables.tf and replace 

configure the aws account

```shell
    aws configure
```
 move to the directory

 Move to the directory

```shell
    cd Terraform
```

Run the stack

```shell
    terraform init
```

```shell
    terraform apply
```
</p>

</details>

<details><summary>packer</summary>

<p>

### Prerequisites

- AWS cli
- packer

### how to run 

go to the directory
```shell
    cd packer
```

configure the aws account

```shell
    aws configure
```

 set your credentials of aws in a enviroment varible

```shell
    export AWS_ACCESS_KEY_ID="<YOUR_AWS_ACCESS_KEY_ID>"
```
```shell
    export AWS_SECRET_ACCESS_KEY="<YOUR_AWS_SECRET_ACCESS_KEY>"
```

init packer
```shell
    packer init .
```

format and validatr the template 
```shell
    packer fmt .
```
```shell
    packer validate .
```

build

format and validatr the template 
```shell
    packer build aws-ubuntu.pkr.hcl
```
</p>


</details>