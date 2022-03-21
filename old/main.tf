terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-north-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-08c308b1bb265e927"
  instance_type = "t1.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
