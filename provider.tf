provider "aws" {
  region  = "eu-north-1"
  profile = "default"
}

data "aws_region" "current" {}

resource "aws_key_pair" "ssh_key_281" {
  key_name   = "FlaskDev_Key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}