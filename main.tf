provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}

data "aws_region" "current" {}

resource "aws_key_pair" "ssh_key_281" {
  key_name   = "FlaskDev_Key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_vpc" "flask_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "FlaskDev_VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.flask_vpc.id}"

  tags = {
    Name = "FlaskDev_IG"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.flask_vpc.id}"

  tags = {
    Name = "FlaskDev_Public_Route_Table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.flask_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "FlaskDev_Subnet"
  }
}

data "template_file" "userdata" {
  template = file("./userdata.sh")
  vars = {
    aws_region       = "${data.aws_region.current.name}"
  }
}

resource "aws_security_group" "flaskdev_sg" {
  name   = "FlaskDev_SG"
  vpc_id = aws_vpc.flask_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5000
    to_port     = 5000
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
    Name = "FlaskDev_Security_Group"
  }
}



resource "aws_instance" "deploy" {
  ami = "ami-08c308b1bb265e927"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.my_subnet.id
  key_name                    = aws_key_pair.ssh_key_281.key_name
  associate_public_ip_address = true
  user_data                   = data.template_file.userdata.rendered
  vpc_security_group_ids      = ["${aws_security_group.flaskdev_sg.id}"]

  provisioner "file" {
    source      = "~/.ssh/id_rsa"
    destination = "/home/ec2-user/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
      agent       = false
      private_key = file("~/.ssh/id_rsa")
    }
  }

  tags = {
    Name = "FlaskDev-Instance"
    Enviroment = "Development"
  }
}