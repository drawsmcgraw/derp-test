resource "aws_s3_bucket" "mongo-backup" {
  bucket = "derp-test-mongo-backup-2023"  # Replace with your desired bucket name
  #acl    = "public-read"  # Set ACL to public-read for public read access

  tags = {
    Name = "derp-test-mongo-backup-2023"
  }
}


resource "aws_s3_bucket_public_access_block" "mongo-backup-public-access" {
  bucket = aws_s3_bucket.mongo-backup.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "world-read-policy" {
  bucket = aws_s3_bucket.mongo-backup.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.mongo-backup.arn}/*"  
        #aws_s3_bucket.mongo-backup.arn
      }
    ]
  })
}

#resource "aws_s3_bucket_acl" "mongo-backup-acl" {
#  bucket = aws_s3_bucket.mongo-backup
#
#  # Grant public read access to all objects
#  grants = [{
#    permissions = ["READ"]
#    type        = "Group"
#    uri         = "http://acs.amazonaws.com/groups/global/AllUsers"
#  }]
#}