# Configure AWS provider
provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

# Create VPC 1
resource "aws_vpc" "myvpc1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc1"
  }
}

# Create Subnet in VPC 1
resource "aws_subnet" "vpc1subnet" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "vpc1subnet"
  }
}

# Create Internet Gateway VPC1
resource "aws_internet_gateway" "vpc1igw" {
  vpc_id = aws_vpc.myvpc1.id
  tags = {
    Name = "vpc1igw"
  }
}

# Create VPC1 Route
resource "aws_route_table" "vpc1route" {
  vpc_id = aws_vpc.myvpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc1igw.id
    
  }
  route {
    cidr_block = "192.168.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc12peering.id
  }
  tags = {
    Name = "vpc1route"
  }
}

# Associate VPC1 Subnet to VPC1 Route
resource "aws_route_table_association" "vpc1ass" {
  subnet_id      = aws_subnet.vpc1subnet.id
  route_table_id = aws_route_table.vpc1route.id
}

# Create VPC 2
resource "aws_vpc" "myvpc2" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "myvpc2"
  }
}

# Create VPC2 Subnet
resource "aws_subnet" "vpc2subnet" {
  vpc_id     = aws_vpc.myvpc2.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "vpc2subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "vpc2igw" {
  vpc_id = aws_vpc.myvpc2.id
  tags = {
    Name = "vpc2igw"
  }
}

# Create VPC2 Route
resource "aws_route_table" "vpc2route" {
  vpc_id = aws_vpc.myvpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc2igw.id
  }
  route {
    cidr_block = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc12peering.id
  }
  tags = {
    Name = "vpc2route"
  }
}

# Associate VPC2 Subnet to VPC2 Route
resource "aws_route_table_association" "vpc2ass" {
  subnet_id      = aws_subnet.vpc2subnet.id
  route_table_id = aws_route_table.vpc2route.id
}

#Create Security Group VPC1
resource "aws_security_group" "allow_ssh_ping_vpc1" {
  name        = "allow_ssh_ping_vpc1"
  description = "Allow SSH and Ping inbound traffic"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "PING from VPC"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_ping_vpc1"
  }
}

#Create Security Group VPC2
resource "aws_security_group" "allow_ssh_ping_vpc2" {
  name        = "allow_ssh_ping_vpc2"
  description = "Allow SSH and Ping inbound traffic"
  vpc_id      = aws_vpc.myvpc2.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    description = "PING from VPC"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_ssh_ping_vpc2"
  }
}
#VPC Peering
resource "aws_vpc_peering_connection" "vpc12peering" {
  peer_vpc_id   = aws_vpc.myvpc2.id #vpc accepter
  vpc_id        = aws_vpc.myvpc1.id #vpc requester
  auto_accept   = true
  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
   tags = {
    Name = "VPC Peering between VPC1 and VPC2"
  }
}

# Create EC2 in VPC1 Subnet
resource "aws_instance" "ec2vpc1subnet" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping_vpc1.id]
  subnet_id = aws_subnet.vpc1subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2vpc1subnet"
  }
}

# Create EC2 in VPC2 Subnet
resource "aws_instance" "ec2vpc2subnet" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping_vpc2.id]
  subnet_id = aws_subnet.vpc2subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2vpc2subnet"
  }
}
