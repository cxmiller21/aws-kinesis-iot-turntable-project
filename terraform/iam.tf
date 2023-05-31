# resource "aws_iam_instance_profile" "kinesis" {
#   name = "${var.project-name}-instance-profile"
#   role = aws_iam_role.ec2.name
# }

# resource "aws_iam_role" "ec2" {
#   name = "${var.project-name}-role"
#   description = "Allows EC2 instances to call AWS services on your behalf."

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

# resource "aws_iam_role_policy_attachment" "ec2_kinesis" {
#   role       = aws_iam_role.ec2.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
# }
