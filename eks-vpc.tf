data "aws_availability_zones" "available" {}

################# VPC ###########################
resource "aws_vpc" "eks-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "eks-vpc"
    Environment = "Development"
  }
}

################# IG #############################
resource "aws_internet_gateway" "eks-ig" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    Name = "eks-ig"
    Environment = "Development"
  }
}

########  PRIVATE SUBNETS #########################
resource "aws_subnet" "private-us-east-1a" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "private-us-east-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_subnet" "private-us-east-1b" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "private-us-east-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_subnet" "private-us-east-1c" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags = {
    "Name" = "private-us-east-1c"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

########### PUBLIC SUBNETS ###############
resource "aws_subnet" "public-us-east-1a" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 

  tags = {
    "Name" = "public-us-east-1a"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_subnet" "public-us-east-1b" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true 

  tags = {
    "Name" = "public-us-east-1b"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_subnet" "public-us-east-1c" {
  vpc_id     = aws_vpc.eks-vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1c"
  map_public_ip_on_launch = true 

  tags = {
    "Name" = "public-us-east-1c"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

############### NAT ###################

resource "aws_eip" "eks_eip" {
  vpc = true

  tags = {
    Name = "eks_eip"
  }
}

resource "aws_nat_gateway" "eks-nat" {
  allocation_id = aws_eip.eks_eip.id
  subnet_id     = aws_subnet.public-us-east-1a.id

  tags = {
    Name = "eks-nat"
  }

  depends_on = [aws_internet_gateway.eks-ig]
}

############## ROUTE TABLES #################

############## Private ######################

resource "aws_route_table" "eks-private-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.eks-nat.id
  }

  tags = {
    Name = "eks-private-rt"
    Terraform = "true"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_route_table_association" "private-us-east-1a" {
  subnet_id      = aws_subnet.private-us-east-1a.id
  route_table_id = aws_route_table.eks-private-rt.id
}

resource "aws_route_table_association" "private-us-east-1b" {
  subnet_id      = aws_subnet.private-us-east-1b.id
  route_table_id = aws_route_table.eks-private-rt.id
}

resource "aws_route_table_association" "private-us-east-1c" {
  subnet_id      = aws_subnet.private-us-east-1c.id
  route_table_id = aws_route_table.eks-private-rt.id
}

################# Public #######################

resource "aws_route_table" "eks-public-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-ig.id
  }
  
  tags = {
    Name = "eks-public-rt"
    Terraform = "true"
    "kubernetes.io/cluster/eks-dev" = "shared"
  }
}

resource "aws_route_table_association" "public-us-east-1a" {
  subnet_id      = aws_subnet.public-us-east-1a.id
  route_table_id = aws_route_table.eks-public-rt.id
}

resource "aws_route_table_association" "public-us-east-1b" {
  subnet_id      = aws_subnet.public-us-east-1b.id
  route_table_id = aws_route_table.eks-public-rt.id
}

resource "aws_route_table_association" "public-us-east-1c" {
  subnet_id      = aws_subnet.public-us-east-1c.id
  route_table_id = aws_route_table.eks-public-rt.id
}