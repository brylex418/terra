###############################################
#### YOU MUST HAVE YOUR AWS CLI CONFIGURED ####
###############################################
provider "aws" {}

#----------- IAM ------------

#S3_access_role

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
    "Effect": "Allow",
    "Action": "S3:*",
    "Resource": "*"
   }
  ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name = "s3_access_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#----------------- VPC ---------------

resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wp_vpc"
  }
}

#IGW

resource "aws_internet_gateway" "wp_internet_gateway" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags = {
    Name = "wp_igs"

  }
}

#Route Tables

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_internet_gateway.id}"
  }

  tags = {
    Name = "wp_public"

  }
}

resource "aws_default_route_table" "wp_private_rt" {
  default_route_table_id = "${aws_vpc.wp_vpc.default_route_table_id}"

  tags = {
    Name = "wp_private"
  }
}

#Subnets

resource "aws_subnet" "wp_public1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_private1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "wp_private2"
  }
}

resource "aws_subnet" "wp_rds1_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "rds_1"
  }
}
resource "aws_subnet" "wp_rds2_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "rds_2"
  }
}


resource "aws_subnet" "wp_rds3_subnet" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"

  tags = {
    Name = "rds_3"
  }
}

# RDS Subnet group 

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name = "wp_rds_subnetgroup"

  subnet_ids = ["${aws_subnet.wp_rds1_subnet.id}",
    "${aws_subnet.wp_rds2_subnet.id}",
    "${aws_subnet.wp_rds3_subnet.id}"
  ]

  tags = {
    Name = "wp_rds_sng"
  }
}

# Subnet and RT assoc

resource "aws_route_table_association" "wp_public1_assoc" {
  subnet_id      = "${aws_subnet.wp_public1_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_assoc" {
  subnet_id      = "${aws_subnet.wp_private2_subnet.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

#Security Groups

resource "aws_security_group" "wp_dev_sg" {
  name        = "wp_dev_sg"
  description = "Used for access to dev instance"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #Allows SSH Access 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allows HTTP

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

resource "aws_security_group" "wp_public_sg" {
  name        = "wp_public_sg"
  description = "used for public access"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #HTTP

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

resource "aws_security_group" "wp_private_sg" {
  name        = "wp_private_sg"
  description = "Used for private access"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #Allows only access from the VPC 

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

}

resource "aws_security_group" "wp_rds_sg" {
  name        = "wp_rds_sg"
  description = "used for rds"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #Provides SQL access

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = ["${aws_security_group.wp_dev_sg.id}",
      "${aws_security_group.wp_public_sg.id}",
      "${aws_security_group.wp_private_sg.id}"
    ]

  }

}

#VPC Endpoint for S3

resource "aws_vpc_endpoint" "wp_private-s3_endpoint" {
  vpc_id       = "${aws_vpc.wp_vpc.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = ["${aws_vpc.wp_vpc.main_route_table_id}",
    "${aws_route_table.wp_public_rt.id}"
  ]
  policy = <<POLICY
{
  "Statement": [
    {
      "Action": "*",
      "Effect": "Allow",
      "Resource": "*",
      "Principal": "*"    
    }
  ]
}
POLICY
}


#--------------S3 Bucket-----------------


resource "random_string" "wp_code_bucket" {
  length = 10
  special = false
  upper = false
  number = false
  
}

resource "aws_s3_bucket" "code" {
  bucket        = "${var.code_bucket_name}-${random_string.wp_code_bucket.id}"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_account_public_access_block" "example" {
  block_public_acls   = true
  block_public_policy = true
}

#--------------RDS-----------------

resource "aws_db_instance" "wp_db" {
  allocated_storage = 200
  engine = "mysql"
  engine_version = "${var.db_engine_version}"
  instance_class = "${var.db_instance_class}"
  name = "${var.dbname}"
  username = "${var.dbuser}"
  password = "${var.dbpassword}"
  db_subnet_group_name = "${aws_db_subnet_group.wp_rds_subnetgroup.name}"
  vpc_security_group_ids = ["${aws_security_group.wp_rds_sg.id}"]
  skip_final_snapshot = true  
}


#--------------EC2-----------------

resource "aws_key_pair" "wp_auth" {
  key_name = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
  
}


resource "aws_instance" "wp_dev" {
  instance_type = "${var.dev_instance_type}"
  ami = "${var.dev_ami}"

  tags = {
    Name = "wp_dev"
    auto-delete = "no"
  }

  key_name = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.s3_access_profile.id}"
  subnet_id = "${aws_subnet.wp_public1_subnet.id}"
  user_data = <<-EOF
   #!/bin/bash
    sudo apt udpate -y
    sudo apt install apache2 -y
    echo "<h1>"Deployed Via Terraform"</h1>" | sudo tee /var/www/html/index.html
    sudo systemctl start apache2
    sudo systemctl enable apache2
    EOF

//  provisioner "local-exec" {
//     command = <<EOD
//   cat <<EOF > aws_hosts
//   [dev]
//   ${aws_instance.wp_dev.public_ip}
//   [dev:vars]
//   s3code=${aws_s3_bucket.code.bucket}
//   domain=${var.domain_name}
//   EOF
//   EOD
//  }
// 
//  COMMENTING OUT UNTIL ANSIBLE IS SETUP
// provisioner "local-exec" {
//  command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.wp_dev.id} ansible-playbook -i aws_hosts wordpress.yml"
// 
// 
 }




#--------------NLB-----------------


resource "aws_lb" "wp_lb" {
  name               = "${var.lb_name}"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.wp_public1_subnet.id}",
  "${aws_subnet.wp_public2_subnet.id}"
  ]

  enable_deletion_protection = false

  tags = {
    Use = "wp_terra_demo"
    auto-delete = "no"
  }
}

resource "aws_lb_listener" "wp_listener" {
  load_balancer_arn = "${aws_lb.wp_lb.id}"
  port              = "80"
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.wp_target_group.id}"
  }
}

resource "aws_lb_target_group" "wp_target_group" {
  name     = "${var.lb_name}tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = "${aws_vpc.wp_vpc.id}"

health_check {
  enabled  = "true"
  interval = "10"
  protocol = "TCP"
  port     = "80"
  healthy_threshold = "3"
  unhealthy_threshold = "3"
}
}

resource "aws_lb_target_group_attachment" "wp_attachment" {
  target_group_arn = "${aws_lb_target_group.wp_target_group.id}"
  target_id        = "${aws_instance.wp_dev.id}"
  port             = "80"
}

