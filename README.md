Code for running SingleM through AWS Batch + Cromwell. Not intended for public use, but go ahead if you want.

## Setup generally for AWS / Cromwell

First setup aws-cli, as here:
https://github.com/mitchac/procedures/blob/6570806bf9da2012e02edf5ee3424639cf2c200c/aws_cli_setup.md

The setup 
https://github.com/mitchac/procedures/blob/6570806bf9da2012e02edf5ee3424639cf2c200c/cromwell_aws_batch.md


Create a public repository at https://console.aws.amazon.com/ecr/repositories - I used public.ecr.aws/m5a0r7u5/singlem-wdl

Then view push commands after clicking on the newly created repository.

Uploading the docker image
```
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/m5a0r7u5

docker tag 7fcb0ae4b481 public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev1.dc630726
```


Commented out mkdocs in script, then create cloudformation script
```
~/git/singlem-wdl-local/aws-genomics-workflows$ bash _scripts/deploy.sh --deploy-region us-east-1 --asset-profile default --asset-bucket s3://cmr-microbiome-cloudformation test
```

Run the cloudformation script
```
(/home/ben/e/mkdocs) b2:20210303:~/git/singlem-wdl-local/aws-genomics-workflows$ source export_gwf_variables.sh
(/home/ben/e/mkdocs) b2:20210303:~/git/singlem-wdl-local/aws-genomics-workflows$ aws cloudformation create-stack \
> --stack-name $AWS_GWFCORE_STACKNAME \
> --template-url $AWS_GWFCORE_TEMPLATE_URL  \
> --parameters \
> ParameterKey=VpcId,ParameterValue=$AWS_VPC_ID \
> ParameterKey=SubnetIds,ParameterValue=$AWS_VPC_SUBNET1_ID\\,$AWS_VPC_SUBNET2_ID \
> ParameterKey=S3BucketName,ParameterValue=$AWS_GWFCORE_S3_BUCKET \
> ParameterKey=ExistingBucket,ParameterValue=true \
> ParameterKey=ArtifactBucketName,ParameterValue=$AWS_GWFCORE_ARTIFACT_BUCKET \
> ParameterKey=ArtifactBucketPrefix,ParameterValue=$AWS_GWFCORE_ARTIFACT_BUCKET_PREFIX \
> ParameterKey=TemplateRootUrl,ParameterValue=$AWS_GWFCORE_TEMPLATE_ROOT_URL \
> --capabilities CAPABILITY_IAM
```
To copy that
```
aws cloudformation create-stack \
--stack-name $AWS_GWFCORE_STACKNAME \
--template-url $AWS_GWFCORE_TEMPLATE_URL  \
--parameters \
ParameterKey=VpcId,ParameterValue=$AWS_VPC_ID \
ParameterKey=SubnetIds,ParameterValue=$AWS_VPC_SUBNET1_ID\\,$AWS_VPC_SUBNET2_ID \
ParameterKey=S3BucketName,ParameterValue=$AWS_GWFCORE_S3_BUCKET \
ParameterKey=ExistingBucket,ParameterValue=true \
ParameterKey=ArtifactBucketName,ParameterValue=$AWS_GWFCORE_ARTIFACT_BUCKET \
ParameterKey=ArtifactBucketPrefix,ParameterValue=$AWS_GWFCORE_ARTIFACT_BUCKET_PREFIX \
ParameterKey=TemplateRootUrl,ParameterValue=$AWS_GWFCORE_TEMPLATE_ROOT_URL \
--capabilities CAPABILITY_IAM
```

public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev1.dc630726