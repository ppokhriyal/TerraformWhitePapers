#Create VPC
#Create 2 subnets in two different AZs ex. us-east-1a and us-easr-1b
#Create Internet Gateway
#Create 2 route-tables and add igw entry
#Associate the subnet with route-tables
#Create security Group for SSH
#Create 2 EC2 instances in two different subnets

# Configure AWS provider

provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxx"
}

# Create VPC
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc"
  }
}

# Create Subnet 1
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet1"
  }
}

# Create Subnet 2
resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "igw"
  }
}

# Create Route for Subnet 1
resource "aws_route_table" "routesubnet1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "routesubnet1"
  }
}

# Associate Subnet1 to Route
resource "aws_route_table_association" "assubnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routesubnet1.id
}

# Create Route for Subnet 2
resource "aws_route_table" "routesubnet2" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "routesubnet2"
  }
}

# Associate Subnet2 to Route
resource "aws_route_table_association" "assubnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routesubnet2.id
}

#Create Security Group
resource "aws_security_group" "allow_ssh_ping" {
  name        = "allow_ssh_ping"
  description = "Allow SSH and Ping inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_ping"
  }
}


# Create EC2 in Subnet 1
resource "aws_instance" "ec2subnet1" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping.id]
  subnet_id = aws_subnet.subnet1.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2subnet1"
  }
}

# Create EC2 in Subnet 2
resource "aws_instance" "ec2subnet2" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping.id]
  subnet_id = aws_subnet.subnet2.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2subnet2"
  }
}
