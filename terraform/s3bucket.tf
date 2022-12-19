data "aws_iam_policy" "s3_for_ec2" {
  arn = var.iam_policy_s3_RO
}

data "aws_iam_policy" "ecr_for_ec2" {
  arn = var.iam_policy_ecr
}

# S3 bucket
resource "aws_s3_bucket" "webserver" {
  bucket = var.s3name
}

resource "aws_s3_object" "settings" {
  for_each = fileset(var.config_link, "*")
  bucket   = aws_s3_bucket.webserver.bucket
  key      = each.value
  source   = "${var.config_link}/${each.value}"
}

# IAM role creation
resource "aws_iam_role" "s3_for_ec2" {
  name = "s3_for_ec2_web"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    Description = "Allow-s3-ecr-RO-for-ec2"
  }
}
resource "aws_iam_role_policy_attachment" "s3_for_ec2" {
  policy_arn = data.aws_iam_policy.s3_for_ec2.arn
  role       = aws_iam_role.s3_for_ec2.name
}

resource "aws_iam_role_policy_attachment" "ecr_for_ec2" {
  policy_arn = data.aws_iam_policy.ecr_for_ec2.arn
  role       = aws_iam_role.s3_for_ec2.name
}

resource "aws_iam_instance_profile" "webserver" {
  name = "WebServer"
  role = aws_iam_role.s3_for_ec2.name
}
