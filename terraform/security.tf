# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }

# resource "aws_security_group" "main" {
#   name        = "${var.project-name}-sg"
#   description = "Allow all traffic"
#   # vpc_id      = aws_vpc.main.id

# #   ingress {
# #     from_port = 0
# #     to_port   = 0
# #     protocol  = -1
# #     self      = true
# #   }

#   ingress {
#       description = "Allow 22 from local IP"
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
