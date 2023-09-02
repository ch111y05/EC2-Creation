resource "aws_vpc" "hashi_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# Private Subnet Configuration
resource "aws_subnet" "hashi_private_subnet" {
  vpc_id                  = aws_vpc.hashi_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-west-2a"

  tags = {
    Name = "dev-private"
  }
}

# Public Subnet Configuration for NAT Gateway
resource "aws_subnet" "hashi_public_subnet" {
  vpc_id                  = aws_vpc.hashi_vpc.id
  cidr_block              = "10.123.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "hashi_internet_gateway" {
  vpc_id = aws_vpc.hashi_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "hashi_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.hashi_public_subnet.id

  tags = {
    Name = "dev-nat"
  }
}

# Route table for private subnet to reach the internet via NAT Gateway
resource "aws_route_table" "hashi_private_rt" {
  vpc_id = aws_vpc.hashi_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hashi_nat_gateway.id
  }

  tags = {
    Name = "dev_private_rt"
  }
}

resource "aws_route_table_association" "hashi_private_assoc" {
  subnet_id      = aws_subnet.hashi_private_subnet.id
  route_table_id = aws_route_table.hashi_private_rt.id
}

resource "aws_security_group" "hashi_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.hashi_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["70.0.0.0/32"] #This is your ip or ip you trust connecting to EC2 instance. /32 is to use this address only.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "hashi_auth" {
  key_name   = "hashikey"
  public_key = file("~/.ssh/hashikey.pub")
}

resource "aws_iam_role" "ssm_role" {
  name = "SSMRoleForEC2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.ssm_role.name
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.hashi_auth.id
  vpc_security_group_ids = [aws_security_group.hashi_sg.id]
  subnet_id              = aws_subnet.hashi_private_subnet.id

  tags = {
    Name = "dev-node"
  }

  root_block_device {
    # volume_size = 8
  }
}