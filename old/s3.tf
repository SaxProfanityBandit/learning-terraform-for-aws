resource "aws_s3_bucket" "flask-artifacts" {
  bucket = "flask-artifacts"

  tags = {
    Name        = "Artifact Storage"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.flask-artifacts.id
  acl    = "private"
}