#To create VPC with cidr block:
resource "aws_vpc" "lesson4handson" {
  cidr_block = "10.0.0.0/24"
}

#Creating public subnets:
resource "aws_subnet" "public1a" {
  
  vpc_id     = aws_vpc.lesson4handson.id
  cidr_block = "10.0.0.0/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "handson4"
  }
}

resource "aws_subnet" "public1b" {
  vpc_id     = aws_vpc.lesson4handson.id
  cidr_block = "10.0.0.64/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "handson4"
  }
}

#Creating private subnets:
resource "aws_subnet" "private1a" {
  vpc_id     = aws_vpc.lesson4handson.id
  cidr_block = "10.0.0.128/26"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name = "handson4"
  }
}

resource "aws_subnet" "private1b" {
  vpc_id     = aws_vpc.lesson4handson.id
  cidr_block = "10.0.0.192/26"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false
  tags = {
    Name = "handson4"
  }
}

#Creating IGW:
resource "aws_internet_gateway" "lesson4IGW" {
  vpc_id = aws_vpc.lesson4handson.id

  tags = {
    Name = "handson4"
  }
}

#Creating NAT-GW:
resource "aws_nat_gateway" "lesson4NATGW" {
  allocation_id = aws_eip.lesson4eip.id
  subnet_id     = aws_subnet.public1a.id
  depends_on = [aws_internet_gateway.lesson4IGW]

  tags = {
    Name = "handson4"
  }
}

#Build EIP for NAT-GW:
resource "aws_eip" "lesson4eip" {
  domain   = "vpc"
  tags = {
    Name = "handson4"
  }
}

#Creating route table for public subnets and associate with public subnets:
resource "aws_route_table" "lesson4publicRT" {
  vpc_id = aws_vpc.lesson4handson.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lesson4IGW.id
  }
}

resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public1a.id
  route_table_id = aws_route_table.lesson4publicRT.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public1b.id
  route_table_id = aws_route_table.lesson4publicRT.id
}




#Creating route table for private subnets and associate with private subnets:
resource "aws_route_table" "lesson4privateRT" {
  vpc_id = aws_vpc.lesson4handson.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lesson4NATGW
  }
}

resource "aws_route_table_association" "private_subnet_a_association" {
  subnet_id      = aws_subnet.private1a.id
  route_table_id = aws_route_table.lesson4privateRT.id
}

resource "aws_route_table_association" "private_subnet_b_association" {
  subnet_id      = aws_subnet.private1b.id
  route_table_id = aws_route_table.lesson4privateRT.id
}

#Creating EC2 instances:
resource "aws_instance" "handson4_1a" {
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_a.id
  key_name               = "tentek"
  security_groups        = [aws_security_group.lesson4secgroup.name]
   user_data              = <<-USERDATA
                              #!/bin/bash
                              yum update -y
                              yum install -y httpd
                              systemctl start httpd
                              systemctl enable httpd
                            USERDATA
}
  

resource "aws_instance" "lesson4_1b" {
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_b.id
  key_name               = "tentek"
  security_groups        = [aws_security_group.lesson4secgroup.name]
   user_data              = <<-USERDATA
                              #!/bin/bash
                              yum update -y
                              yum install -y httpd
                              systemctl start httpd
                              systemctl enable httpd
                            USERDATA
}

#Create security group:
resource "aws_security_group" "lesson4secgroup" {
  name        = "handson4"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

#Creating target group:
resource "aws_lb_target_group" "lesson4TG" {
  name     = "lesson4lg-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lesson4handson.id
}

#Attatch public 1a instance to target group:
resource "aws_lb_target_group_attachment" "public1ainstance_to_targetgroup" {
  target_group_arn = aws_lb_target_group.lesson4TG
  target_id = aws_instance.handson4_1a
}
#Attatch public 1b instance to target group:
resource "aws_lb_target_group_attachment" "public1binstance_to_targetgroup" {
  target_group_arn = aws_lb_target_group.lesson4TG
  target_id = aws_instance.handson4_1b
}

#Creating ALB sec group:
resource "aws_security_group" "alb_secgroup_lessson4" {
  name        = "alb_secgroup_lesson4"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Creating listener for httpd:
resource "aws_lb_listener" "httpd_listener" {
  load_balancer_arn = aws_lb.lesson4_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# #Create listener for https:
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.lesson4_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::insert certificate ID here"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lesson4TG.arn
  }
}

#Create SSL certificate:
resource "aws_acm_certificate" "lesson4" {
  domain_name       = "apahomov.com"
  subject_alternative_names = "*.apahomov.com"
  validation_method = "DNS"
    tags = {
      Name = "lesson4"
    }
}

#Certificate validation:


# #Creating ALB:
# resource "aws_lb" "lesson4_alb" {
#   name               = "handson4"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_secgroup_lessson4.id]
#   subnets            = [aws_subnet.private1a.id, aws_subnet.private1b.id ]

#   tags = {
#     Name = "handson4"
#   }
# }


# ### create ssl cert:
# resource "aws_acm_certificate" "cert" {
#   domain_name               = "rustemtentech.com"
#   subject_alternative_names = ["*.rustemtentech.com"]
#   validation_method         = "DNS"

#   tags = {
#     Name = "my_cert"
#   }
# }

# ### validate ssl cert:
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = "Z06527831PAUBUFRMEW8O"
# }

#Create CNAME: