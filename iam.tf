resource "aws_iam_role" "s3-role" {
  name = "EC2S3WriteRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

#
# rename this on next rebuild
#
resource "aws_iam_instance_profile" "s3-write-profile" {
  name = "s3-write-profile"
  role = aws_iam_role.s3-role.name
}

resource "aws_iam_policy" "mongo-ec2-policy" {
  name        = "S3WritePolicy"
  description = "Allows writing to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "ec2:*"
        ],
        Effect   = "Allow",
        Resource = [
            aws_s3_bucket.mongo-backup.arn,
            "${aws_s3_bucket.mongo-backup.arn}/*"
          #"arn:aws:s3:::your-bucket-name/*",
          #"arn:aws:s3:::your-bucket-name"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_write_attachment" {
  policy_arn = aws_iam_policy.mongo-ec2-policy.arn
  role       = aws_iam_role.s3-role.name
}


