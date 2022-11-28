# S3 bucket
/*resource "aws_s3_bucket" "webserver" {
  bucket = "rpeklov-webserver-data"
}

/# IAM role creation
resource "aws_iam_role" "s3_for_ec2" {
  name = "s3_for_ec2_web"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ]
        }
    ]
  })
  tags = {
    Description = "Allow-s3-RO-for-ec2"
  }

    ingress {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.response_body)}/32"]
  }

}*/