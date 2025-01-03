# This configuration does the following:

# 1. Creates a VPC with public and private subnets.
# 2. Sets up firewall rules to allow HTTP traffic (port 80) to the VM and communication between the VM and the database (port 3306 for MySQL).
# 3. Creates a VM instance in the public subnet with Nginx installed.
# 4. Creates a Cloud SQL MySQL instance in the private subnet.
# 5. Creates a database and a user for the database.
# 6. Outputs the public IP of the VM and the private IP of the database.

# To use this configuration:

# 1. Replace `your-project-id` with your actual GCP project ID.
# 2. Save the code in a file named `main.tf`.
# 3. Run `terraform init` to initialize Terraform.
# 4. Run `terraform plan` to see the execution plan.
# 5. Run `terraform apply` to create the resources.

# Important notes:

# - The database password is set to "change-me". You should change this to a secure password.
# - The `deletion_protection` for the database is set to `false` for easy cleanup. In a production environment, you should set this to `true`.
# - The VM has a public IP for easy access, but in a production environment, you might want to use a bastion host or VPN for secure access.
# - This setup allows the VM to connect to the database, but you'll need to configure your application to use the correct connection details.
# - Remember to run `terraform destroy` when you're done to avoid unnecessary charges.

# This configuration provides a basic setup. Depending on your specific needs, you might want to add more security measure, configure backups for the database, set up monitoring, etc.

Create account in GCP.
Install gcloud on your distributer machine (in my case linux ubuntu 24.04)
Go to APIs & Services and enable it.
Open to IAM service, choose your account, grant access, Select Role and add Service Account User/Service Networking Admin/Compute Network Admin.
Run gcloud auth application-default login and allow gcloud credentials access.
Alternatively you can create service account and create keys for particular service account and download and the save keys.json with information to connect to GCP.

Terraform command:
terraform init
terraform plan
terraform apply

# First, destroy the database instance
terraform destroy -target google_sql_database_instance.db_instance

# Then destroy the service networking connection
terraform destroy -target google_service_networking_connection.private_vpc_connection

# Finally, destroy everything else
terraform destroy
