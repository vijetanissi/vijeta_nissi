terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}
 
provider "aws" {
  region = "us-west-2" # Or your desired AWS region
}
 
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "2397888-s3-bucket" 
 
  tags = {
    Project     = "StaticWebsiteDeployment"
    Environment = "Production"
  }
}
 
resource "aws_s3_bucket_website_configuration" "static_website_config" {
  bucket = aws_s3_bucket.static_website_bucket.id
 
  index_document {
    suffix = "index.html"
  }
}
 
resource "aws_s3_bucket_public_access_block" "static_website_bucket_public_access_block" {
  bucket = aws_s3_bucket.static_website_bucket.id
 
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
 
resource "aws_s3_bucket_policy" "static_website_bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id
 
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": [
          "${aws_s3_bucket.static_website_bucket.arn}/*"
        ]
      }
    ]
  })
 
  depends_on = [
    aws_s3_bucket_public_access_block.static_website_bucket_public_access_block,
    aws_s3_bucket_website_configuration.static_website_config
  ]
}
 
resource "local_file" "index_html" {
  content  = <<-EOT
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>My Static Website</title>
</head>
<body>
<h1>Welcome to My Static Website!</h1>
<p>This page is served from an S3 bucket using Terraform.</p>
</body>
</html>
  EOT
  filename = "${path.module}/index.html"
}
 
resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.static_website_bucket.id
  key    = "index.html"
  source = local_file.index_html.filename
  acl    = "public-read"
  content_type = "text/html"
 
  depends_on = [
    aws_s3_bucket_policy.static_website_bucket_policy
  ]
}
 
output "website_endpoint" {
  value = aws_s3_bucket_website_configuration.static_website_config.website_endpoint
  description = "The S3 static website endpoint."
}
 
output "website_domain" {
  value = aws_s3_bucket_website_configuration.static_website_config.website_domain
  description = "The S3 static website domain name."
}
