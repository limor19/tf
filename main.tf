provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
  Name = "vpc-jenkins"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "set-master-default-rt-assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "jenkins-sg" {
  
  name        = "jenkins-sg"
  description = "Allow TCP/8080 & TCP/22"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins-master" {
  ami           = "ami-0bef6cc322bfff646" 
  instance_type = "t2.micro"
  key_name      = "limor"
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.jenkins-sg.id]
  subnet_id             = aws_subnet.public.id
  
  tags = {
    Name = "jenkins-master"
  }
}

resource "null_resource" "ansible_provisioner" {
  depends_on = [aws_instance.jenkins-master]

  provisioner "local-exec" {
    command = "ansible-playbook -i '${aws_instance.jenkins-master.public_ip},' -u ec2-user  ~/ansible_templates/install_jenkins.yaml"
  
  
  }
}

 


output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.jenkins-master.public_ip
}



