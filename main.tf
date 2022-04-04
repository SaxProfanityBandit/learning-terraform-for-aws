provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}

data "aws_region" "current" {}

resource "aws_key_pair" "ssh_key_281" {
  key_name   = "FlaskDev_Key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
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