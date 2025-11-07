AWS Practice 

Title: Automated onboarding of AWS resources into Datadog dashboards & alerts using CloudWatch + Terraform + CI/CD

summary
This POC demonstrates a fully automated flow that takes AWS resource metric data (pushed to Datadog via the existing CloudWatch integration) and automatically creates Datadog dashboards and alert monitors whenever a new AWS resource is onboarded. The automation is driven by Terraform scripts that are executed by a CI/CD pipeline . When a new resource appears, a small onboarding event JSON payload is published which triggers the pipeline to run terraform applications. The Terraform code uses Datadog provider and Datadog APIs to create metrics/dashboards/monitors dynamically.

Goal: show end-to-end automation so that new resources require no manual Datadog configuration.
Terraform-managed Datadog resources (monitors, dashboards)
CI/CD pipeline to apply Terraform when a new resource JSON appears
Example code for automation (Terraform, small AWS Lambda to publish onboarding events)

Architecture

AWS Resource --> CloudWatch metrics -> Datadog (integration) -> Datadog host/metrics visible.
When new AWS resource created -> Event to onboarding channel (S3/EventBridge/Lambda) -> commit JSON to repo push webhook -> CI/CD triggers -> Terraform plan/apply uses data dog provider to create monitor & dashboard entries -> Datadog shows dashboard & active alerts.

Components:
AWS CloudWatch (source of metrics)
Datadog (destination for metrics and alerts)
Terraform code (datadog provider + resources)
CI/CD (GitHub) to run Terraform
Onboarding trigger (small AWS) that posts a JSON file or triggers a repo webhook

Flow details
•	AWS resources created (e.g. new EC2 instance, RDS, Lambda function).
•	CloudWatch starts publishing metrics (native or custom). Datadog AWS integration ingests those metrics.
•	A lightweight onboarding event is emitted (this can be Event Bridge rule for resource creation, or a manual/system that writes a JSON to resources/ folder of the repo).
•	The onboarding event triggers CI/CD (for example committing a file to a Gilt repo or calling a CI webhook) which contains the new resource's metadata (resource name, type, tags, metric names).
•	CI/CD runs terraform plan and terraform apply on the Terraform code that uses var.resource_name to create: Datadog dashboard widgets for the resource's CloudWatch-derived metrics
•	Datadog monitors/alerts that reference the metric and have escalation/notification channels
•	Datadog receives these resources via Terraform (using the Datadog provider) and the dashboards/alerts are available and active.
•	Optional: test runner posts a synthetic metric or pings the resource to validate alert firing.






Prerequisites & secrets
•	Terraform = Latest version at 1.4 and above
•	Datadog Terraform provider
•	Datadog API key and APP key (store as secrets): DD_API_KEY, DD_APP_KEY
•	AWS credentials for CI if Terraform needs to create cloud infra in this POC Terraform config focuses on Datadog only — AWS creds may be needed for onboarding lambda deployment)
•	GitHub Actions runner or CI runner with access to secrets
•	GitHub token with repo writes access (GITHUB_TOKEN or personal token) for automation that commits resource JSON files
Security: store keys in secret manager (GitHub secrets / AWS Secrets Manager). Use least privilege for Datadog keys (scoped to monitors/dashboards where possible).

Terraform approach
•	Use the datadog provider to manage dashboards and monitors.
•	Parameterize by resource_name, resource_type, region, and metric_name.
•	Store a template module modules/datadog-onboard that, given resource metadata, creates a datadog_dashboard and datadog_monitor.
•	CI/CD will dynamically generate a simple tfvars json file or update variables and run terraform apply.

Core Terraform files
providers.tf
terraform {
required_providers {
datadog = {
source = "DataDog/datadog"
version = ">= 3.0.0"
}
}
}

provider "datadog" {
api_key = var.datadog_api_key
app_key = var.datadog_app_key
}
variables.tf
variable "datadog_api_key" { type = string }
variable "datadog_app_key" { type = string }
variable "resource_name" { type = string }
variable "resource_type" { type = string }
variable "metric_name" { type = string }
variable "env" { type = string, default = "dev" }

modules/datadog-onboard/main.tf

for Example: create a dashboard and simple monitor for a resource
resource "datadog_dashboard" "resource_dashboard" {
title = "${var.resource_type} - ${var.resource_name} Dashboard"
description = "Auto-created dashboard for ${var.resource_name}"
layout_type = "ordered"

widget {
timeseries_definition {
request {
q = "avg:aws.${var.metric_name}{resource:${var.resource_name}}"
display_type = "line"
style { }
}
title = "${var.metric_name} for ${var.resource_name}"
}
}
}

resource "datadog_monitor" "resource_monitor" {
name = "${var.resource_type} ${var.resource_name} ${var.metric_name} - threshold"
type = "metric alert"
query = "avg(last_5m):avg:aws.${var.metric_name}{resource:${var.resource_name}} > 80"
message = <<EOF
Alert: ${var.resource_name} ${var.metric_name} breached threshold.
{{#is_alert}}Send notification to #ops-team{{/is_alert}}
EOF
tags = ["auto:onboard", "resource:${var.resource_name}", "env:${var.env}"]
thresholds {
critical = 80.0
}
}

root module call
module "onboard" {
source = "./modules/datadog-onboard"

resource_name = var.resource_name
resource_type = var.resource_type
metric_name = var.metric_name
env = var.env
}

NOTE: The metric query aws.${var.metric_name}{resource:${var.resource_name}} is illustrative. Actual metric names/tags depend on how Datadog ingests CloudWatch metrics in your account. Replace resource tag and metric names according to your Datadog AWS integration tagging schema (for example host, instance, dbinstanceidentifier, functionname, or custom tags).

Automation: how to push new resource metadata into Terraform

API-push to Terraform service
•	A Lambda calls a deployment service that runs Terraform –(ex- an API endpoint you host that runs terraform apply with the given variables).

AWS Lambda to create resource JSON in GitHub -using python
This Lambda demonstrates how to push a JSON file to a GitHub repo which will trigger the GitHub Actions workflow.
# lambda_onboard.py (example)
import json
import os
import requests

GITHUB_API = https://api.github.com
REPO = os.environ['REPO']  e.g "org/repo"
BRANCH = os.environ.get('BRANCH','main')
TOKEN = os.environ['GITHUB_TOKEN']

headers = {
'Authorization': f'token {TOKEN}',
'Accept': 'application/vnd.github+json'
}

def lambda_handler(event, context):
# event should contain resource metadata
resource = {
'resource_name': event['detail']['resourceName'],
'resource_type': event['detail']['resourceType'],
'metric_name': event['detail'].get('metricName','ec2.cpuutilization'),
'env': event['detail'].get('env','prod')
}

path = f"resources/{resource['resource_name']}.json"
content = json.dumps(resource, indent=2)

# Get current commit's SHA to create new file on branch using contents API
url = f"{GITHUB_API}/repos/{REPO}/contents/{path}"
data = {
'message': f"Add resource {resource['resource_name']} for Datadog onboarding",
'content': content.encode('utf-8').decode('utf-8').encode('base64') if False el


Store your Datadog API Key securely
DatadogApiKeySecret:
Type: "AWS::SecretsManager::Secret"
Properties:
Name: "datadog-api-key"
SecretString: !Sub '{"DD_API_KEY":"d3b0cff9af9c00cdacff57fd9ac2d8d7"}'
DatadogTaskExecutionRole:
Type: "AWS::IAM::Role"
Properties:
RoleName: "datadog-task-execution-role"
AssumeRolePolicyDocument:
Version: "2012-10-17"
Statement:
- Effect: "Allow"
Principal:
Service:
- "ecs-tasks.amazonaws.com"
Action:
- "sts:AssumeRole"
Path: "/"
ManagedPolicyArns:
- "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
Policies:
- PolicyName: "datadog-secret-access"
PolicyDocument:
Version: "2012-10-17"
Statement:
- Effect: "Allow"
Action:
- "secretsmanager:GetSecretValue"
Resource:
- !Ref DatadogApiKeySecret
ECSTaskDefinition:
Type: "AWS::ECS::TaskDefinition"
Properties:
Family: "datadog-agent"
NetworkMode: "bridge"
RequiresCompatibilities:
- "EC2"
Cpu: "256"
Memory: "512"
ExecutionRoleArn: !GetAtt DatadogTaskExecutionRole.Arn
ContainerDefinitions:
- Name: "datadog-agent"
Image: "public.ecr.aws/datadog/agent:7.50.3"
Memory: 512
Cpu: 100
Essential: true
Environment:
- Name: "DD_SITE"
Value: "datadoghq.com"
Secrets:
- Name: "DD_API_KEY"
ValueFrom: !Sub "${DatadogApiKeySecret}:DD_API_KEY::"
MountPoints:
- ContainerPath: "/var/run/docker.sock"
SourceVolume: "docker_sock"
ReadOnly: true
- ContainerPath: "/host/sys/fs/cgroup"
SourceVolume: "cgroup"
ReadOnly: true
- ContainerPath: "/host/proc"
SourceVolume: "proc"
ReadOnly: true
Volumes:
- Name: "docker_sock"
Host:
SourcePath: "/var/run/docker.sock"
- Name: "proc"
Host:
SourcePath: "/proc/"
- Name: "cgroup"
Host:
SourcePath: "/sys/fs/cgroup/"
ECSService:
Type: "AWS::ECS::Service"
Properties:
ServiceName: "datadog-agent-service"
Cluster: "REPLACE_WITH_YOUR_CLUSTER_NAME"
TaskDefinition: !Ref ECSTaskDefinition
SchedulingStrategy: "DAEMON"
LaunchType: "EC2"


Overview
Secrets Manager secret for your Datadog API key
An IAM Role (for ECS tasks) allowing access to that secret
An ECS Task Definition for running the Datadog Agent container
An ECS Service to deploy the Datadog Agent on ECS (EC2 launch type)
So, when executed, this CloudFormation stack will deploy the Datadog Agent as a daemon on every EC2 instance in your ECS cluster to collect metrics, logs, and traces.

DatadogApiKeySecret
-creates a secret in AWS Secrets Manager named datadog-api-key.
-Stores your Datadog API key in JSON format.
Why we do we require-
 - The Datadog Agent needs your API key to send metrics and logs to your Datadog account.
 - Keeping it in Secrets Manager ensures secure storage instead of embedding it directly into your task definition.



DatadogTaskExecutionRole
-	Creates an IAM Role that ECS tasks can assume when they start.
-	The ecs-tasks.amazonaws.com principal means it can be assumed only by ECS tasks.
ManagedPolicyArns
This AWS-managed policy gives the ECS task permissions to:
Pull container images from ECR
Write logs to CloudWatch
Use ECS Exec features

Custom Policy
Adds a custom inline policy allowing this ECS task to read the secret you just created (datadog-api-key).
Without this, the container couldn’t retrieve your Datadog API key from Secrets Manager.

ECSTaskDefinition
Defines the Datadog Agent ECS Task configuration — think of this as a “recipe” for how to run the Datadog Agent container.
Family: Logical name for the task (used by ECS Service)
NetworkMode: Uses Docker’s bridge networking (since it’s EC2-based, not Fargate)
RequiresCompatibilities: Set to EC2 (so runs on ECS EC2 cluster, not Fargate)
ExecutionRoleArn: Uses the IAM Role created earlier so it can access Secrets Manager, ECR, CloudWatch, etc.




ContainerDefinitions
This container runs the Datadog Agent Docker image (v7.50.3).
Marks it as Essential, meaning if this container fails, ECS restarts the task.

Environment
Defines environment variables for the agent — here you specify which Datadog site your account is in (datadoghq.com, datadoghq.eu, etc.).

Secrets
•	Pulls the API key from Secrets Manager (datadog-api-key secret).
•	ECS injects this value as an environment variable DD_API_KEY inside the container securely at runtime.

MountPoints / Volumes
These mount points allow the Datadog agent container to access host-level metrics:
/var/run/docker.sock → communicates with Docker daemon to collect container metrics
/proc and /sys/fs/cgroup → read system-level data like CPU, memory, and network usage
This is critical for Datadog to monitor all containers and EC2 host metrics.

ECSService
Creates an ECS Service named datadog-agent-service.
Runs the Datadog Agent task definition you created above.
Cluster → replace with your ECS cluster name.
LaunchType: EC2 → ensures it runs on EC2-based ECS clusters (not Fargate).
SchedulingStrategy: DAEMON → ensures one Datadog agent runs on every EC2 instance in the cluster (like a DaemonSet in Kubernetes).
This means every EC2 host in your ECS cluster will have one Datadog agent collecting metrics from:
All containers on that host
Host-level performance (CPU, Memory, Disk, Network)

AWS Resources and services created

I AM user and user group
<img width="975" height="461" alt="image" src="https://github.com/user-attachments/assets/9c12e80c-2668-4725-8188-6c8893cdc73b" />


Added user to user group
 <img width="975" height="441" alt="image" src="https://github.com/user-attachments/assets/e9372bb5-720f-4b25-88c9-52b75e068b2f" />
 
 <img width="975" height="420" alt="image" src="https://github.com/user-attachments/assets/074fe9c7-def4-4227-b054-fc324cb63c70" />
<img width="975" height="420" alt="image" src="https://github.com/user-attachments/assets/853b6d58-93d5-4630-9c4a-faa3fc59a45b" />
<img width="975" height="400" alt="image" src="https://github.com/user-attachments/assets/8664dc81-5a2c-4081-931b-8854dcdf1c73" />

EC2
 <img width="975" height="459" alt="image" src="https://github.com/user-attachments/assets/a3df757a-2b5a-439b-a3e7-c8fc50ee66d8" />
<img width="975" height="421" alt="image" src="https://github.com/user-attachments/assets/3fae8d86-334b-432c-b130-6a0ebd4272c7" />

<img width="975" height="455" alt="image" src="https://github.com/user-attachments/assets/50e52a2b-14b7-4931-8066-da011f9c01b8" />

 <img width="975" height="452" alt="image" src="https://github.com/user-attachments/assets/1c1d125e-7729-4706-b041-47469098ad69" />

<img width="975" height="455" alt="image" src="https://github.com/user-attachments/assets/35662785-c1bf-49b8-9b30-e6592215ea84" />
<img width="975" height="461" alt="image" src="https://github.com/user-attachments/assets/5d6bc6bd-a0a4-4430-9184-310abf4948ad" />

<img width="975" height="467" alt="image" src="https://github.com/user-attachments/assets/8b38d2c9-6e1e-48bb-b783-e668ee592bec" />

 <img width="975" height="415" alt="image" src="https://github.com/user-attachments/assets/2673c58a-64c1-4f68-98c6-e759d2078a0b" />


 


 


 

Created the Aws access key’s secret’s and downloaded same on local machine. 
AWS Cli installed
 <img width="975" height="68" alt="image" src="https://github.com/user-attachments/assets/4760c97c-30d5-467a-b205-557a8ffb876c" />

Billing-
 
<img width="975" height="379" alt="image" src="https://github.com/user-attachments/assets/18221c70-f156-4639-a3e2-f0272d0a0b1e" />


VPC
 <img width="975" height="395" alt="image" src="https://github.com/user-attachments/assets/bd28ae23-d243-4be5-af11-1cab9ab4bc2c" />

Subnets-
 
<img width="975" height="417" alt="image" src="https://github.com/user-attachments/assets/7a1cdcb7-ac66-451d-b8c6-6bd3ba4de708" />
<img width="975" height="417" alt="image" src="https://github.com/user-attachments/assets/950887b5-c197-4a6f-8a0d-69b30270f812" />

 

Routes table-
 <img width="975" height="415" alt="image" src="https://github.com/user-attachments/assets/366aa979-bb19-4cba-97a9-651834be418b" />

Internet Gateways –
<img width="975" height="417" alt="image" src="https://github.com/user-attachments/assets/588d8ddc-2b10-4d63-a552-cf477ead54c6" />

 

Attached the Subnets
<img width="975" height="462" alt="image" src="https://github.com/user-attachments/assets/c67ff5e2-4ba4-42be-8271-836260b34195" />

 <img width="975" height="421" alt="image" src="https://github.com/user-attachments/assets/010caef5-8ea2-4a88-a0c3-170874bc4eff" />

<img width="975" height="430" alt="image" src="https://github.com/user-attachments/assets/5087727a-aa62-461b-8aed-77e0e4fb2020" />

 

 

NAT Gateways-

Private Nat gateways
 <img width="975" height="411" alt="image" src="https://github.com/user-attachments/assets/19e46b2e-f834-4294-8824-38a0a1edbeb4" />


Public Nat gateways
<img width="975" height="419" alt="image" src="https://github.com/user-attachments/assets/6171de75-ab7d-4058-950f-fcfcca940b94" />
 

EC2 /webserver Security group
 <img width="975" height="425" alt="image" src="https://github.com/user-attachments/assets/f9195dd9-265b-41c0-8b0b-3b5a76449c66" />


Inbound rules
 <img width="975" height="445" alt="image" src="https://github.com/user-attachments/assets/21fa112b-da0f-41cb-8085-a25a7763bd76" />


Outbound Roules
 <img width="975" height="415" alt="image" src="https://github.com/user-attachments/assets/b4abe177-9c18-4868-935d-1c8376347f00" />


Keypair for SSH to ec2 access
 <img width="975" height="415" alt="image" src="https://github.com/user-attachments/assets/d08bdc2d-f7e7-44be-b377-af1d8d78e427" />

S3 Bucket
<img width="975" height="356" alt="image" src="https://github.com/user-attachments/assets/8d66a9e8-5dfd-4d33-bac9-836e6a6976bf" />
<img width="975" height="391" alt="image" src="https://github.com/user-attachments/assets/d9f8dade-7e70-486f-95ce-85fe49b036a2" />

 
 
Bucket versioning Enabled 
<img width="975" height="454" alt="image" src="https://github.com/user-attachments/assets/ccf676c0-96db-4dc7-8fef-b92afed55d43" />

Server access Enabled -  
<img width="975" height="408" alt="image" src="https://github.com/user-attachments/assets/293e0aaf-acfd-4464-af06-1a6e93d4e5ff" />
 <img width="975" height="421" alt="image" src="https://github.com/user-attachments/assets/48333258-1215-43e2-9f7e-8549385e2482" />
<img width="975" height="417" alt="image" src="https://github.com/user-attachments/assets/d0ccfb54-7a52-426f-b080-c01307330107" />

<img width="975" height="427" alt="image" src="https://github.com/user-attachments/assets/548927d8-38ef-4861-b697-7482911c1de3" />

 <img width="975" height="399" alt="image" src="https://github.com/user-attachments/assets/4afd15cf-31b7-4078-99cc-057ba2abf0b9" />



 

