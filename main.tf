data "template_file" "userdata" {
  template = file("./userdata.sh")
  vars = {
    aws_region       = "${data.aws_region.current.name}"
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