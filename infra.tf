terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }

  backend "s3" {
    bucket = "terraform-infra-state-12344321343"
    key    = "infra-state.tfstate"
    region = var.region
  }
}


provider "aws" {
  region = var.region
}


# resource "aws_instance" "web" {
#   ami           = "ami-0287a05f0ef0e9d9a"
#   instance_type = "t2.micro"
#   key_name = "demo-linux-11"

#   tags = {
#     Name = "Machine_tag_manual"
#   }
# }


# resource "aws_eip" "eip_instance" {
#   instance = aws_instance.web.id
#   }

#creating vpc



#creating the aws-instance

resource "aws_instance" "Mumbai-ec2" {
  ami                         = "ami-01d152f18c99d3f79" #"ami-0287a05f0ef0e9d9a"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.mumbai-key.id
  subnet_id                   = aws_subnet.mumbai-subnet-1a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mumbai_security_group.id]


  tags = {
    Name = "Mumbai-EC2-machine"
  }
}

resource "aws_instance" "Mumbai-ec2-2" {
  ami           = "ami-01d152f18c99d3f79" #"ami-0287a05f0ef0e9d9a"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.mumbai-key.id
  subnet_id     = aws_subnet.mumbai-subnet-1b.id
  #associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.mumbai_security_group.id]

  tags = {
    Name = "Mumbai-EC2-machine-2"
  }
}

#creating the key pair

resource "aws_key_pair" "mumbai-key" {
  key_name   = "mumbai-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDIBwIcvxSrmfb1JO4jy1r56Cjf5wHAMOFtFHhwH0uGNa/IAzISGJ0OLcWzXKDtvMrGED00KWQ8L882mQyu1lvH7ZSGWiqG8Y07V7H4GWbSjUS3MDbbLMrxmIaePzRKke0FsI1V4dP5g1pG4N9MDEcfxHTM6tb/BQD0E7PNh8LZvxTXrLvPo5vDfvO2JbHyhnAVgW1dt37ZGU1l/S2HMzoHsgivPFVk0IVI6AYbVz8FP7KexOA8kyYJ26ettoSsy84sN4hNWb6w0tVb/nAVmkUnuh716tBUjpahWTcMIgJnM5m8IK0NDRENHMqEAVqQiYYXKAV+vMtf9WiNOQkRm52xGXP6l77+G7knlFqx5QNlr7clkLHY2+6JYVal0E9JAOROjGLKAXhDWuT2PQT718RGOUACPCbwyRT2KSgmK62EssVtP+MMx/Bqydk2RqpmkPf+7b0k3NZaSmdcNwYL4wLf+s/uM+3LQzHfHLwx0zkeuwoUGbSZ97tJB64Krk5Apvk= Amol@DESKTOP-2MVQBON"
}

#creating security group

resource "aws_security_group" "mumbai_security_group" {
  name        = "mumbai_security_group"
  description = "Allow 80 and 22 port as inbound"
  vpc_id      = aws_vpc.mumbai-vpc.id

  ingress {
    description = "22 from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["103.221.75.221/32", "0.0.0.0/0"]
  }

  ingress {
    description = "80 from outside"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_80_22"
  }
}

#creating the internet gateway

resource "aws_internet_gateway" "mumbai_IGW" {
  vpc_id = aws_vpc.mumbai-vpc.id

  tags = {
    Name = "Mumbai_IGW"
  }
}

#create route table

resource "aws_route_table" "mumbai_public_RT" {
  vpc_id = aws_vpc.mumbai-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mumbai_IGW.id
  }

  tags = {
    Name = "Mumbai_public_RT"
  }
}

resource "aws_route_table_association" "subnet_1a_association" {
  subnet_id      = aws_subnet.mumbai-subnet-1a.id
  route_table_id = aws_route_table.mumbai_public_RT.id
}

resource "aws_route_table_association" "subnet_1b_association" {
  subnet_id      = aws_subnet.mumbai-subnet-1b.id
  route_table_id = aws_route_table.mumbai_public_RT.id
}

#create private RT


resource "aws_route_table" "mumbai_private_RT" {
  vpc_id = aws_vpc.mumbai-vpc.id

  tags = {
    Name = "Mumbai_private_RT"
  }
}

resource "aws_route_table_association" "subnet_1c_association" {
  subnet_id      = aws_subnet.mumbai-subnet-1c.id
  route_table_id = aws_route_table.mumbai_private_RT.id
}


#create Load balancer

resource "aws_lb" "mumbai_lb" {
  name               = "Mumbai-webapp"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mumbai_security_group.id]
  subnets            = [aws_subnet.mumbai-subnet-1a.id, aws_subnet.mumbai-subnet-1b.id]

  #enable_deletion_protection = true/false

  tags = {
    Environment = "production"
  }
}


#create listerner

resource "aws_lb_listener" "mumbai-listener" {
  load_balancer_arn = aws_lb.mumbai_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-TG.arn
  }
}

#target group

resource "aws_lb_target_group" "mumbai-TG" {
  name     = "mumbai-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai-vpc.id
}

#target group attachment

resource "aws_lb_target_group_attachment" "attach-1" {
  target_group_arn = aws_lb_target_group.mumbai-TG.arn
  target_id        = aws_instance.Mumbai-ec2.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach-2" {
  target_group_arn = aws_lb_target_group.mumbai-TG.arn
  target_id        = aws_instance.Mumbai-ec2-2.id
  port             = 80
}

#creating the launch template
resource "aws_launch_template" "mumbai_launch_template" {
  name      = "mumbai_launch_template"
  image_id  = "ami-0287a05f0ef0e9d9a"
  key_name  = aws_key_pair.mumbai-key.id
  vpc_security_group_ids = [aws_security_group.mumbai_security_group.id]
  instance_type = "t2.micro"
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Mumbai-Instance-via-ASG"
    }
  }

  user_data = filebase64("example.sh")

}

#create auto scaling group

resource "aws_autoscaling_group" "mumbai_asg" {
  name = "Mumbai_ASG"  
  vpc_zone_identifier = [aws_subnet.mumbai-subnet-1a.id, aws_subnet.mumbai-subnet-1b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.mumbai-TG-2.arn]

  launch_template {
    id      = aws_launch_template.mumbai_launch_template.id
    version = "$Latest"
  }
}

#create Load balancer 2

resource "aws_lb" "mumbai_lb_2" {
  name               = "Mumbai-webapp-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mumbai_security_group.id]
  subnets            = [aws_subnet.mumbai-subnet-1a.id, aws_subnet.mumbai-subnet-1b.id]

  #enable_deletion_protection = true/false

  tags = {
    Environment = "production"
  }
}


#create listerner 2

resource "aws_lb_listener" "mumbai-listener-2" {
  load_balancer_arn = aws_lb.mumbai_lb_2.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mumbai-TG-2.arn
  }
}

#target group 2

resource "aws_lb_target_group" "mumbai-TG-2" {
  name     = "mumbai-TG-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mumbai-vpc.id
}
