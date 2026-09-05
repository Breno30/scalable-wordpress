# Scalable WordPress on AWS

A small Terraform project that shows how to run WordPress with a production-style AWS architecture instead of a single public server.

The stack keeps the web servers private, distributes traffic through an Application Load Balancer, scales EC2 instances automatically, and separates shared files, database data, and cache traffic into managed AWS services.

[![WordPress request flow through AWS](diagrams/request-flow.svg)](diagrams/request-flow.mmd)

_A request travels from the public load balancer to private WordPress instances and managed AWS data services. Select the diagram to view its Mermaid source._

## Why this project is useful

- **Safer network design:** only the load balancer is open to web traffic. EC2 and RDS have no public access.
- **Horizontal scaling:** an Auto Scaling group can add WordPress instances as CPU usage grows.
- **Shared WordPress uploads:** EFS gives every instance access to the same media files.
- **Managed data services:** RDS runs MySQL and ElastiCache Serverless runs Valkey.
- **No database password in Terraform:** RDS creates the password in Secrets Manager, and EC2 reads it through a restricted IAM role.
- **Repeatable setup:** EC2 bootstraps Nginx, PHP-FPM, WP-CLI, WordPress, and the EFS mount automatically.

## Architecture

The VPC spans `us-east-1a` and `us-east-1b`. Each private application subnet uses a NAT gateway in the same Availability Zone for outbound package downloads. The database subnets have no internet route.

See the [architecture diagrams](diagrams/README.md) and the [networking walkthrough](docs/public-private-networking.md) for more detail.

> Valkey is provisioned and the PHP Redis extension is installed, but WordPress is not yet configured to use the cache endpoint.

## Deploy

You need Terraform, AWS credentials, an Amazon Linux 2023 AMI ID, and an EC2 key pair named `wordpress` in `us-east-1`.

Create `terraform.tfvars`:

```hcl
ami_id        = "ami-xxxxxxxxxxxxxxxxx"
instance_type = "t3.micro"
```

Then deploy:

```bash
export AWS_REGION=us-east-1
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Open the URL printed by Terraform, or verify it from the terminal:

```bash
curl --fail --location "http://$(terraform output -raw url)/"
```

The first boot can take several minutes while WordPress and its packages are installed. When finished, destroy the stack to stop ongoing charges:

```bash
terraform destroy
```

## Deployment evidence

This stack has been created and torn down from the local Terraform state. The previous state snapshot records the VPC and six subnets, two NAT gateways, ALB, Auto Scaling group, RDS, EFS mount targets, Valkey cache, IAM resources, and service-specific security groups. The current state is empty, so there is no live public URL or ongoing deployment to demonstrate.

For a new deployment, these commands provide reproducible evidence:

```bash
terraform state list
terraform output -raw url
curl --fail --location "http://$(terraform output -raw url)/"
```

The final `curl` verifies the complete request path: ALB → Nginx → PHP-FPM → WordPress.

## Estimated cost

Expect roughly **$130–$150 per month** for a small, continuously running deployment in `us-east-1`, before meaningful traffic or free-tier credits. This assumes one `t3.micro` EC2 instance, a Single-AZ `db.t3.micro` RDS database with 20 GB of storage, light EFS and Valkey usage, and 730 hours per month.

| Service | Approximate monthly cost |
| --- | ---: |
| Two NAT gateways | $66 |
| Application Load Balancer and light LCU usage | $17–$23 |
| EC2 `t3.micro` | $8 |
| RDS `db.t3.micro` and 20 GB storage | $15–$22 |
| ElastiCache Serverless for Valkey | From $6 |
| Public IPv4 addresses | About $15 |
| EFS, Secrets Manager, and small variable charges | $1–$5 |
| **Estimated total** | **$130–$150/month** |

The two NAT gateways are the largest fixed cost. A development version could use one NAT gateway and save about **$33/month**, with lower Availability Zone resilience. Data transfer, NAT processing, ALB capacity, cache requests, EFS usage, backups, and CPU credits can increase the total.

Prices change, so confirm the estimate with the [AWS Pricing Calculator](https://calculator.aws/) before deploying. The estimate is based on AWS pricing for [NAT Gateway](https://aws.amazon.com/vpc/pricing/), [Application Load Balancer](https://aws.amazon.com/elasticloadbalancing/pricing/), [EC2 T3](https://aws.amazon.com/ec2/instance-types/t3/), [RDS for MySQL](https://aws.amazon.com/rds/mysql/pricing/), [ElastiCache](https://aws.amazon.com/elasticache/pricing/), and [Secrets Manager](https://aws.amazon.com/secrets-manager/pricing/), checked September 2026.

## Current scope

This repository demonstrates the infrastructure and bootstrap flow. Before treating it as a production platform, add HTTPS, stronger backup and deletion protection, Systems Manager access, monitoring, a dedicated health endpoint, and WordPress cache configuration.
