
#################################################################################################

# Add this at the beginning of your configuration file
data "google_service_account" "terraform_sa" {
  account_id = "207132388378-compute@developer.gserviceaccount.com"  # The part before @your-project.iam.gserviceaccount.com
}

resource "google_project_iam_member" "service_networking_admin" {
  project = "terrafom-436819" # set your projectID
  role    = "roles/servicenetworking.networksAdmin"
  member  = "serviceAccount:${data.google_service_account.terraform_sa.email}"
}

resource "google_project_iam_member" "compute_network_admin" {
  project = "terrafom-436819"
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${data.google_service_account.terraform_sa.email}"
}



##########################################################################################


# Configure the Google Cloud provider
provider "google" {
  #credentials = file("/home/eav/Code/home-assignments/microsoft/terraform/terrafom-436819-47dc73b32b0a.json")
  project = "terrafom-436819"
  region  = "us-central1"
}

# Create a VPC network
resource "google_compute_network" "vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false

  lifecycle {
    create_before_destroy = true
  }
}

# Create public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = "us-central1"
}

# Create private subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.vpc.id
  region        = "us-central1"
  private_ip_google_access = true
}

# Create a firewall rule to allow HTTP traffic to VM
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Create a firewall rule to allow VM to database communication
resource "google_compute_firewall" "allow_db" {
  name    = "allow-db"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]  # MySQL default port
  }

  source_tags = ["http-server"]
  target_tags = ["database"]
}

# Create a public IP address for the VM
resource "google_compute_address" "vm_ip" {
  name = "vm-public-ip"
}

# Create a service account for the VM
resource "google_service_account" "vm_service_account" {
  account_id   = "vm-service-account"
  display_name = "Service Account for VM"
}

# Add IAM roles to the service account
resource "google_project_iam_member" "vm_sa_roles" {
  project = "terrafom-436819"
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.vm_service_account.email}"
}

# Create a VM instance in the public subnet
resource "google_compute_instance" "vm_instance" {
  name         = "my-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      nat_ip = google_compute_address.vm_ip.address
    }
  }

  metadata_startup_script = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              service nginx start
              EOF

   service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["cloud-platform"]
  }

  # Add metadata to allow OS Login
  metadata = {
    enable-oslogin = "TRUE"
  }
}

######################################################################
# Enable Service Networking API
resource "google_project_service" "servicenetworking" {
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iap_api" {
  service = "iap.googleapis.com"
  disable_on_destroy = false
}

# Reserve IP range for VPC peering
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

# Create VPC peering connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  depends_on = [google_project_service.servicenetworking]

    lifecycle {
    create_before_destroy = true
  }
    #google_sql_database_instance.db_instance
}
##################################################################################



# Cloud SQL Admin API enablement
resource "google_project_service" "sql_admin_api" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# Add Cloud SQL Admin role to service account
resource "google_project_iam_member" "cloudsql_admin" {
  project = "terrafom-436819"
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${data.google_service_account.terraform_sa.email}"
}


# Create a Cloud SQL instance (MySQL) in the private subnet
resource "google_sql_database_instance" "db_instance" {
  name             = "my-database-instance-${random_id.db_name_suffix.hex}"
  database_version = "MYSQL_8_0"
  region           = "us-central1"


  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  deletion_protection = false
  depends_on = [
    google_service_networking_connection.private_vpc_connection,
    google_project_service.sql_admin_api,
    google_project_iam_member.cloudsql_admin
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create a database
resource "google_sql_database" "database" {
  name     = "my-database"
  instance = google_sql_database_instance.db_instance.name
}

# Create a database user
resource "google_sql_user" "users" {
  name     = "mysql-user"
  instance = google_sql_database_instance.db_instance.name
  password = "sql123pass"  # Change this to a secure password
}

# Output the public IP address of the VM
output "vm_public_ip" {
  value = google_compute_address.vm_ip.address
}

# Output the private IP address of the database
output "db_private_ip" {
  value = google_sql_database_instance.db_instance.private_ip_address
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# resource "google_sql_database_instance" "db_instance" {
#   name             = "my-database-instance-${random_id.db_name_suffix.hex}"
# }  

#####################################################################
# Create a firewall rule to allow IAP traffic
resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]  # SSH port
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["http-server"]
}
