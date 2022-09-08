variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "mykey"
}


variable "public_key_path" {
   description = "Enter the path to the SSH Public Key to add to AWS."
   default     = "mykey.pem"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

# Ubuntu
variable "aws_amis" {
  default = {
    us-east-1 = "ami-052efd3df9dad4825"
  }
}

