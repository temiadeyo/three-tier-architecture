# Building a Three-Tier Architecture on AWS

## Overview

This project demonstrates how to deploy a three-tier WordPress application on AWS using Terraform.

A three-tier architecture separates an application into three logical layers: web, application, and database. Each layer has a distinct responsibility, improving separation of concerns and allowing communication between tiers to be controlled.

The architecture consists of:

-   **Web Tier**: An internet-facing Application Load Balancer (ALB) that distributes incoming HTTP traffic across the application servers.
-   **Application Tier**: WordPress running on EC2 instances across two Availability Zones, managed by an Auto Scaling Group (ASG).
-   **Database Tier**: Amazon RDS for MySQL, configured for Multi-AZ deployment to support automatic database failover.

Amazon EFS provides shared storage for WordPress application files.

I used Terraform to provision the AWS infrastructure and EC2 user data to automate the initial configuration of the application servers.

----------

## Architecture

![3 Tier Architecture Diagram](/images/three-tier-architecture.png)


The infrastructure is deployed inside a custom Amazon VPC across two Availability Zones.

The VPC contains:

-   Two public subnets for the Application Load Balancer and NAT Gateways.
-   Two private application subnets for the EC2 instances.  
-   Two private database subnets for the RDS subnet group.
    
    
### Web Tier

This layer provides the public entry point to the WordPress application through the Application Load Balancer. The ALB is deployed across the two public subnets and receives HTTP requests from users and forwards them to the EC2 servers in the application tier through a target group. Health checks are used to determine whether each application server is ready to receive traffic. The ALB security group allows HTTP traffic from the internet, while the EC2 servers' security group only allows HTTP traffic originating from the ALB.

----------

### Application Tier

The application tier uses an Auto Scaling Group to manage WordPress application servers across two Availability Zones. The ASG maintains a minimum and desired capacity of two EC2 instances and can scale out to a maximum of four instances based on average CPU utilization.

A Launch Template defines the instance configuration, including the AMI, instance type, security group, IAM instance profile, and EC2 user data. The EC2 instances run Apache HTTP Server, PHP, and WordPress, and are deployed in private application subnets without public IP addresses. NAT Gateways provide outbound internet connectivity for tasks such as downloading software updates.
    
EC2 user data automates the initial server setup by installing the required software and PHP extensions, mounting EFS, configuring WordPress files and permissions, and setting up the connection to Amazon RDS.

Amazon Elastic File System (EFS) provides shared storage for WordPress core files, themes, plugins, and uploaded media. Both application servers mount the same filesystem, allowing them to access shared application files across the two Availability Zones.

The instances are also configured with the AWS Systems Manager Agent and an IAM instance profile that grants the permissions required for Systems Manager core functionality. This configuration supports administrative access through Systems Manager Session Manager without requiring a bastion host or direct SSH access, provided the required service connectivity and permissions are available.

----------

### Database Tier

Amazon Relational Database Service (RDS) for MySQL provides the managed database layer for the WordPress application. It stores the application's structured data, including posts, pages, user accounts, comments, and site settings. 

The RDS instance is configured for Multi-AZ deployment, with a standby in a separate Availability Zone. RDS synchronously replicates database changes to the standby and can automatically fail over to it if the primary DB instance fails, improving database availability while keeping the database endpoint consistent for the application.

The RDS instance is deployed in the private database subnets and is not publicly accessible. The application servers connect to the database over TCP port 3306 to retrieve and update WordPress data as users interact with the website.

The database security group allows MySQL traffic only from the application server security group, preventing direct database connections from the public internet and restricting access to the application tier.

----------

## Key AWS Services

-   **Amazon VPC**: Provides the isolated network environment for the application.
-   **Amazon EC2**: Runs the Apache, PHP, and WordPress application servers.
-   **Application Load Balancer**: Distributes incoming HTTP traffic across the application servers.
-   **Amazon EFS**: Provides shared storage for WordPress application files.
-   **Amazon RDS for MySQL**: Provides the managed relational database for WordPress.
-   **NAT Gateway**: Provides outbound internet connectivity from private application subnets.
-   **Internet Gateway**: Provides internet connectivity for resources in the public subnets.
-   **Elastic IP**: Provides public IP addresses for the NAT Gateways.
-   **Security Groups**: Control traffic between the ALB, EC2 instances, EFS, and RDS.
        
----------

## Prerequisites

Before deploying this project, ensure you have the following:

-   **AWS Account**: To provision cloud resources.
-   **AWS CLI**: Installed and configured with AWS credentials. See the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html).
-  **IAM User**: An IAM user with the permissions required to create and manage the AWS resources defined in the Terraform configuration.
-   **Terraform**: Installed on your local machine.
- **Code editor (VS Code recommended)**: Use VS Code with the Terraform extension for syntax highlighting, code formatting, and a better development experience.
-  **Git (Optional)**: Installed if you intend to clone the project repository.
    
----------

## Infrastructure Deployment

### Terraform Structure
```
terraform/
├── providers.tf               # Terraform requirements and AWS provider
├── variables.tf               # Input variable declarations
├── datasources.tf             # AWS data sources such as AMI and AZ lookups
├── locals.tf                  # Local values and EC2 user-data configuration
├── networking.tf              # VPC, subnets, gateways, and routing
├── security.tf                # Security groups and network access rules
├── compute.tf                 # ALB, target group, Launch Template, and Auto Scaling 
├── storage.tf                 # EFS filesystem and mount targets
├── database.tf                # RDS MySQL instance and DB subnet group
├── iam.tf                     # EC2 IAM role and Systems Manager policy
├── outputs.tf                 # ALB DNS name and database endpoint outputs
└── terraform.tfvars.example   # Example variable values
```


After configuring your AWS credentials, review `variables.tf` to identify the required input variables. Use `terraform.tfvars.example` as a reference to create and configure your local `terraform.tfvars` file.

Navigate to the Terraform directory and run the following commands to initialize Terraform, validate the configuration, review the proposed changes, and deploy the infrastructure.

```
terraform init
terraform validate
terraform plan
terraform apply
```
After testing is complete, remove the resources created by Terraform to avoid unnecessary AWS charges.
```
terraform destroy
```

----------

## Results

I validated the deployment by testing application access, checking the load balancer target health, verifying the EFS mount, reviewing the RDS configuration, and accessing an application instance through Systems Manager.

**Load Balancer and Application Servers**:

The Application Load Balancer was active across two Availability Zones. Both EC2 application servers registered with the target group and passed their health checks.

![ALB Target Group Health](/images/alb-target-group.png)
  
![Application Load Balancer](/images/application-load-balancer.png)

**WordPress Application**:

The WordPress application was accessed through the ALB DNS name. The initial setup was completed, and the WordPress admin dashboard was accessible.

![WordPress Homepage](/images/wordpress-homepage.png)

![WordPress Admin Dashboard](/images/wordpress-admin-dashboard.png)
  

**Shared Storage**:

Amazon EFS was configured with mount targets across both Availability Zones to provide shared WordPress file storage.

![EFS SharedStorage](/images/efs-shared-storage.png)

  
**Database Availability**:

Amazon RDS for MySQL was configured for Multi-AZ deployment, with a secondary Availability Zone to support failover.

  ![RDS Multi-AZ 1](/images/rds-multi-az-1.png)
	
 ![RDS Multi-AZ 2](/images/rds-multi-az-2.png)

**Instance Administration with AWS Systems Manager**:

AWS Systems Manager Session Manager was used to access a private EC2 application instance without requiring a bastion host or direct SSH access. The session was used to verify that Apache was running, the local HTTP request returned a `200 OK` response, and the shared EFS filesystem was mounted at `/var/www/html`.

 ![SSM Administration 1](/images/ssm-admin-1.png)

 ![SSM Administration 2](/images/ssm-admin-2.png)

----------

## Technical Decisions

-   **Multi-AZ Application Deployment**: Distributed the application servers across two Availability Zones to reduce dependence on a single instance or Availability Zone.
-   **Private Application Servers**: Placed EC2 instances in private subnets without public IP addresses to reduce direct internet exposure and route application traffic through the ALB.
-   **Shared Storage with EFS**: Chose shared storage to keep WordPress files consistent across application servers.
-   **Managed Database with RDS**: Used Amazon RDS for MySQL instead of running MySQL on the EC2 instances, separating database responsibilities from the application layer.
-   **NAT Gateway per Availability Zone**: Deployed a NAT Gateway in each Availability Zone to support AZ-local outbound routing and reduce dependence on a single NAT Gateway, while accepting the additional infrastructure cost.
-   **Security Groups**: Restricted communication between the ALB, application servers, EFS, and RDS to the required traffic sources and ports.
- **No Bastion Host**: Used AWS Systems Manager Session Manager to provide administrative access without a dedicated bastion instance, reducing infrastructure costs and avoiding inbound SSH access.

----------

## Production Readiness Improvements

The following improvements would further strengthen the architecture's security, monitoring, and operational resilience for production use.

-   **HTTPS with AWS Certificate Manager (ACM)**: Configure an HTTPS listener on the Application Load Balancer using an ACM certificate and redirect HTTP traffic to HTTPS.
-   **Custom Domain with Amazon Route 53**: Configure a custom domain and DNS records pointing to the Application Load Balancer to provide a more user-friendly URL.
-   **Content Delivery with Amazon CloudFront**: Place CloudFront in front of the application to cache eligible static content and improve content delivery for geographically distributed users.
-   **Secrets Management with AWS Secrets Manager**: Store database credentials in AWS Secrets Manager instead of passing passwords through Terraform variables.
-   **Database Security**: Enable deletion protection and retain final snapshots to protect database data.
----------

## Conclusion

This project demonstrates how Terraform can be used to provision a three-tier WordPress application on AWS. It covers VPC networking, subnet design, load balancing, shared storage with EFS, a managed MySQL database, security group configuration, and automated EC2 configuration.

The architecture is designed to support high availability, scalability, and reliability through Multi-AZ deployment, application server auto scaling, and managed AWS services. 

The project provided practical experience with Terraform, AWS networking, application deployment, and infrastructure validation.


