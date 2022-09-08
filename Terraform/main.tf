provider "aws" {
  region = "${var.aws_region}"
}

# create VPC 
resource "aws_vpc" "ec2vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create internet gateway 
resource "aws_internet_gateway" "ec2gateway" {
  vpc_id = "${aws_vpc.ec2vpc.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.ec2vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ec2gateway.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "ec2_subnet" {
  vpc_id                  = "${aws_vpc.ec2vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# create the security group
resource "aws_security_group" "security_group_elb" {
  name        = "security_group_elb"
  description = "ec2 elb"
  vpc_id      = "${aws_vpc.ec2vpc.id}"


  # HTTP access 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create security group to access SSH and HTTP
resource "aws_security_group" "security_group_ec2" {
  name        = "security_group_ec2"
  description = "acces to ssh and port 80"
  vpc_id      = "${aws_vpc.ec2vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_elb" "elb" {
  name = "ec2-elb"

  subnets         = ["${aws_subnet.ec2_subnet.id}"]
  security_groups = ["${aws_security_group.security_group_elb.id}"]
#   instances       = ["${aws_instance.nginx_server.id}"]
  
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}


# resource "aws_instance" "nginx_server" {

# tags = {
#     Name = "nginx_server"
#   }

#   ami = "${lookup(var.aws_amis, var.aws_region)}"
#   instance_type = "t2.micro"
#   key_name = "${var.key_name}"
#   vpc_security_group_ids = ["${aws_security_group.security_group_ec2.id}"]
#   subnet_id = "${aws_subnet.ec2_subnet.id}"

# # nginx installation
#   provisioner "file" {
#     source      = "nginx.sh"
#     destination = "/tmp/nginx.sh"
#   }
#   # Execute the nginx.sh file
#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x /tmp/nginx.sh",
#       "sudo /tmp/nginx.sh"
#     ]
#   }

# # conection
#   connection {
#     type        = "ssh"
#     host        = self.public_ip
#     user        = "ubuntu"
#     private_key = "${file(var.public_key_path)}"
#   }
# }

#create the autoscaling group

resource "aws_launch_configuration" "aws_launch_configuration" {
  name = "ec2_lauch"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.security_group_ec2.id}"]
  key_name = "${var.key_name}"
  user_data = "${file("nginx.sh")}"

# # nginx installation
#   provisioner "file" {
#     source      = "nginx.sh"
#     destination = "/tmp/nginx.sh"
#   }
#   # Execute the nginx.sh file
#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x /tmp/nginx.sh",
#       "sudo /tmp/nginx.sh"
#     ]
#   }
}


resource "aws_autoscaling_group" "ec2-autoescaling-group" {

  name = "autoescaling-group-ec2"
  max_size = "2"
  min_size = "1"
  desired_capacity = "2"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.aws_launch_configuration.name}"
  load_balancers = ["${aws_elb.elb.name}"]
  vpc_zone_identifier = ["${aws_subnet.ec2_subnet.id}"]

}
