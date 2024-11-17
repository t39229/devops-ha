Home assignment | Microsoft
The following file contains 2 folders for Intermediate Task: Automate Infrastructure Provisioning with explanation and instruction how to deploy task1 and task2:
1. Task1 - deploy infrastructure using Terraform in GCP cloud
2. Task2 - contain yaml describes infrastructure deploymnet using CloudFormation.

   1. Task1 - deploy infrastructure using Terraform in GCP cloud.
      
  This configuration does the following:
1. Creates a VPC with public and private subnets.
2. Sets up firewall rules to allow HTTP traffic (port 80) to the VM and communication between the VM and the database (port 3306 for MySQL).
3. Creates a VM instance in the public subnet with Nginx installed.
4. Creates a Cloud SQL MySQL instance in the private subnet.
5. Creates a database and a user for the database.
6. Outputs the public IP of the VM and the private IP of the database.
To use this configuration:
1. Replace your-project-id with your actual GCP project ID.
2. Save the code in a file named main.tf.
3. Run terraform init to initialize Terraform.
4. Run terraform plan to see the execution plan.
5. Run terraform apply to create the resources.
Important notes:
- The database password is set to "change-me". You should change this to a secure password.
- The deletion_protection for the database is set to false for easy cleanup. In a production environment, you should set this to true.
- The VM has a public IP for easy access, but in a production environment, you might want to use a bastion host or VPN for secure access.
- This setup allows the VM to connect to the database, but you'll need to configure your application to use the correct connection details.
- Remember to run terraform destroy when you're done to avoid unnecessary charges.
This configuration provides a basic setup. Depending on your specific needs, you might want to add more security measure, configure backups for the database, set up monitoring, etc.
Create account in GCP. Install gcloud on your distributer machine (in my case linux ubuntu 24.04) Go to APIs & Services and enable it. Open to IAM service, choose your account, grant access, Select Role and add Service Account User/Service Networking Admin/Compute Network Admin. Run gcloud auth application-default login and allow gcloud credentials access. Alternatively you can create service account and create keys for particular service account and download and the save keys.json with information to connect to GCP.

Terraform command: terraform init terraform plan terraform apply

First, destroy the database instance
terraform destroy -target google_sql_database_instance.db_instance

Then destroy the service networking connection
terraform destroy -target google_service_networking_connection.private_vpc_connection

Finally, destroy everything else
terraform destroy

Task2 - contain yaml describes infrastructure deploymnet using CloudFormation.
This YAML file is an AWS CloudFormation template designed to set up a network infrastructure with a Virtual Private Cloud (VPC), subnets, an EC2 instance, and an RDS database. Here's a breakdown of each section:

How to deploy: Clone infrastructure2.yaml file on your local directory. Login into AWS console, open CloudFormation service. Click on Create stack and choose "Upload a template file" under Specify template. Choose file and uplod infrastructure2.yaml and click Next. Provide a stack name and click Next-->Next-->Submit You can follow in progress of deploymnets in Resources and Output sections until it's change to CREATE_COMPLETED. Verify your deploymnet by SSH into your instance in EC2. You can destroy your Stack by clicking on Delete Stack.

General Information AWSTemplateFormatVersion: Specifies the version of the CloudFormation template format being used. Description: Provides a brief description of what the template does. Resources This section defines all the AWS resources that will be created.

VPC (Virtual Private Cloud)

VPC: Creates a VPC with a CIDR block of 10.0.0.0/16. DNS support and hostnames are enabled, and it is tagged with a name. Subnets

PublicSubnet: A public subnet with a CIDR block of 10.0.1.0/24 is created. It is configured to automatically assign public IPs to instances launched within it. PrivateSubnet1 and PrivateSubnet2: Two private subnets with CIDR blocks 10.0.2.0/24 and 10.0.3.0/24 respectively. They are placed in different availability zones for redundancy. Internet Gateway and Route Tables

InternetGateway: Creates an internet gateway to allow internet access. AttachGateway: Attaches the internet gateway to the VPC. PublicRouteTable: A route table for the public subnet. PublicRoute: Adds a route to the route table that directs all outbound traffic (0.0.0.0/0) to the internet gateway. PublicSubnetRouteTableAssociation: Associates the public subnet with the public route table. Security Groups

EC2SecurityGroup: Allows HTTP access (port 80) from anywhere to the EC2 instance. RDSSecurityGroup: Allows MySQL access (port 3306) from the EC2 instance to the RDS database. EC2 Instance

EC2Instance: Launches an EC2 instance of type t3.micro in the public subnet. It uses a specified Amazon Linux 2 AMI and is associated with the EC2SecurityGroup. RDS Database

RDSInstance: Creates an RDS database instance of type db.t3.micro with MySQL as the engine. It is configured with a database name, master username, and password. The instance is secured by the RDSSecurityGroup and uses a specified DB subnet group. DBSubnetGroup: Defines a subnet group for the RDS instance, using the two private subnets for high availability. Outputs This section provides information about the resources created, which can be useful for other CloudFormation stacks or for users.

InstanceId: Outputs the ID of the EC2 instance. DBEndpoint: Outputs the endpoint address of the RDS database, which is necessary for connecting to the database.
