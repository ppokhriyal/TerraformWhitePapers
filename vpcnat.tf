# Configure AWS provider
provider "aws" {
  region     = "us-east-1"
  access_key = "xxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxx"
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

# Create PublicSubnet
resource "aws_subnet" "publicsubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "publicsubnet"
  }
}

# Create PrivateSubnet
resource "aws_subnet" "privatesubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "privatesubnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "igw"
  }
}

# Create Elastic IP
resource "aws_eip" "eip" {
  vpc      = true
}

# Create PublicRoute
resource "aws_route_table" "publicroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "publicroute"
  }
}

# Create PrivateRoute
resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.myvpc.id
  route {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.natgw.id
  }
  tags = {
    Name = "privateroute"
  }
}

# Associate PublicSubnet to PublicRoute
resource "aws_route_table_association" "publicass" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.publicroute.id
}

# Associate PrivateSubnet to PrivateRoute
resource "aws_route_table_association" "privateass" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.privateroute.id
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
    Name = "allow_ssh_ping"
  }
}

# Create EC2 in PublicSubnet
resource "aws_instance" "ec2publicsubnet" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping.id]
  subnet_id = aws_subnet.publicsubnet.id
  associate_public_ip_address = true
  tags = {
    Name = "ec2publicsubnet"
  }
}

# Create EC2 in PrivateSubnet
resource "aws_instance" "ec2privatesubnet" {
  ami           = "ami-0dba2cb6798deb6d8"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "mysshkey"
  security_groups = [aws_security_group.allow_ssh_ping.id]
  subnet_id = aws_subnet.privatesubnet.id
  tags = {
    Name = "ec2privatesubnet"
  }
}

# Create NatGateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.publicsubnet.id
  tags ={
      Name = "natgw"
  }
}
