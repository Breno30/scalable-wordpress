# Public and private networking walkthrough

This stack uses three network tiers. The tiers are defined by routing and security rules, not merely by subnet names.

## Step 1: Keep the entry point public

The public subnets (`10.0.1.0/24` and `10.0.2.0/24`) have a default route to the Internet Gateway. The internet-facing Application Load Balancer and NAT gateways live here. The ALB security group accepts public HTTP traffic.

## Step 2: Move application services into private subnets

The private application subnets (`10.0.21.0/24` and `10.0.22.0/24`) contain the Auto Scaling instances, EFS mount targets, and Valkey cache. EC2 network interfaces explicitly disable public IP addresses. The application security group accepts HTTP only from the ALB security group.

Each private route table sends outbound internet traffic to the NAT gateway in the same Availability Zone. This lets an instance download operating-system and WordPress packages without allowing the internet to initiate a connection to that instance.

Administrative shell access uses AWS Systems Manager Session Manager. The instances do not require SSH keys, public IP addresses, or an inbound port 22 rule.

## Step 3: Keep the database isolated

The database subnets (`10.0.11.0/24` and `10.0.12.0/24`) have no default route to an Internet Gateway or NAT gateway. RDS is also configured with `publicly_accessible = false`, and its security group accepts MySQL only from the application security group.

## Step 4: Follow one incoming request

1. A browser connects to the public ALB.
2. The ALB forwards HTTP to a healthy EC2 instance in a private subnet.
3. WordPress can connect privately to RDS, EFS, and Valkey.
4. Only the ALB sends the response back to the browser.

The intended exposure is therefore:

```text
Internet -> public ALB -> private WordPress -> isolated/private data services
```

## Cost and availability trade-off

The configuration creates one NAT gateway per Availability Zone. In `us-east-1`,
that is currently $0.045 per gateway-hour plus $0.045 per GB processed, so the
two-gateway default is about $65.70 per 730-hour month before data processing.
This avoids making one zone depend on the other for outbound access. A learning
or development environment could use one NAT gateway to reduce the fixed cost by
about half, accepting lower availability and cross-zone routing. VPC endpoints
can later reduce some NAT traffic.
