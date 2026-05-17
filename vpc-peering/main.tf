# IMPORTANT: ONLY UNCOMMENT/RUN BELOW AFTER S3 BUCKET HAS BEEN CREATED FOR STORING TF STATE

# Create primary VPC
resource "aws_vpc" "primary_vpc" {
  cidr_block       = var.primary_vpc_cidr
  provider         = aws.primary_region
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"

  tags = {
    Name = "Primary-VPC-${var.primary_region}"
  }
}

# Create secondary VPC
resource "aws_vpc" "secondary_vpc" {
  cidr_block       = var.secondary_vpc_cidr
  provider         = aws.secondary_region
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"

  tags = {
    Name = "Secondary-VPC-${var.secondary_region}"
  }
}

# Create subnet in Primary VPC
resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary_region
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.primary_subnet_cidr
  availability_zone       = data.aws_availability_zones.primary.names[0] # Select value of availabiiliy region, first in the list
  map_public_ip_on_launch = true

  tags = {
    Name        = "Primary-Subnet-${var.primary_region}"
    Environment = "Demo"
  }
}

# Create subnet in Secondary VPC
resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary_region
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.secondary_subnet_cidr
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "Secondary-Subnet-${var.secondary_region}"
    Environment = "Demo"
  }
}

# Create the primary IGW
resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary_region
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "Primary-IGW-${var.primary_region}"
    Environment = "Demo"
  }
}

# Create the secondary IGW
resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary_region
  vpc_id = aws_vpc.secondary_vpc.id

  tags = {
    Name = "Secondary-IGW-${var.secondary_region}"
    Environment = "Demo"
  }
}

# Create route table for Primary VPC
resource "aws_route_table" "primary_rt" {
  provider = aws.primary_region
  vpc_id   = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name        = "Primary-Route-Table"
    Environment = "Demo"
  }
}

# Create route table for Secondary VPC
resource "aws_route_table" "secondary_rt" {
  provider = aws.secondary_region
  vpc_id   = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name        = "Secondary-Route-Table"
    Environment = "Demo"
  }
}

# Associate route table with Primary subnet
resource "aws_route_table_association" "primary_rta" {
  provider       = aws.primary_region
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

# Associate route table with Secondary subnet
resource "aws_route_table_association" "secondary_rta" {
  provider       = aws.secondary_region
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

# VPC Peering Connection (Requester side - Primary VPC)
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.primary_region
  vpc_id      = aws_vpc.primary_vpc.id # Source VPC ID
  peer_vpc_id = aws_vpc.secondary_vpc.id # Destination VPC ID
  peer_region = var.secondary_region
  auto_accept = false

  tags = {
    Name        = "Primary-to-Secondary-Peering"
    Environment = "Demo"
    Side        = "Requester"
  }
}

# VPC Peering Connection (Accepter side - Secondary VPC)
resource "aws_vpc_peering_connection_accepter" "secondary_accepter" {
  provider    = aws.secondary_region
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept = true

  tags = {
    Name        = "Secondary-to-Primary-Peering"
    Environment = "Demo"
    Side        = "Accepter"
  }
}

# Add route from Primary VPC to Secondary VPC in Primary Subnet route table
resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary_region
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

# Add route from Secondary VPC to Primary VPC in Secondary Subnet route table
resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary_region
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

# Security Group for Primary VPC EC2 instance
resource "aws_security_group" "primary_sg" {
  provider    = aws.primary_region
  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC instance"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "SSH from anywhere" # Need to secure/harden
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC" # Ping to test connectivity
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Primary-VPC-SG"
    Environment = "Demo"
  }
}

# Security Group for Secondary VPC EC2 instance
resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary_region
  name        = "secondary-vpc-sg"
  description = "Security group for Secondary VPC instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    description = "All traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Secondary-VPC-SG"
    Environment = "Demo"
  }
}


# EC2 Instance in Primary VPC
resource "aws_instance" "primary_instance" {
  provider               = aws.primary_region
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.primary_key_name

  user_data = local.primary_user_data

  tags = {
    Name        = "Primary-VPC-Instance"
    Environment = "Demo"
    Region      = var.primary_region
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

# EC2 Instance in Secondary VPC
resource "aws_instance" "secondary_instance" {
  provider               = aws.secondary_region
  ami                    = data.aws_ami.secondary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  key_name               = var.secondary_key_name

  user_data = local.secondary_user_data

  tags = {
    Name        = "Secondary-VPC-Instance"
    Environment = "Demo"
    Region      = var.secondary_region
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}


# # =======================================================================================

# IMPORTANT: CREATE S3 BUCKET FOR STORING STATE FILE; COMMENT OUT ONCE THE REMOTE STATE BUCKET HAS BEEN CREATED

resource "aws_s3_bucket" "terraform_state" {
  bucket = "vpc-peering-state-bucket" # Must be globally unique

  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SEQUENCE OF STEPS
# 1. terraform init, terraform apply with backend commented out and remote state bucket uncommented
# 2. terraform destroy all resources except the remote state bucket and associated resources (remote state bucket will be created but with empty/fresh state now)
# 3. uncomment the backend in terraform.tf
# 4. run terraform init and type yes
# 5. trigger the CI/CD pipeline on GitLab by changing a file
# 6. manually destroy the architecture for cleanup