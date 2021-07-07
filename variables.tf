variable "ami" {
  type        = string
  description = "The AMI used to create the server"
}

variable "instance_type" {
  type        = string
  description = "The AWS instance type (https://aws.amazon.com/ec2/instance-types/)"
}

variable "username" {
  type        = string
  description = "The linux username to log into the remote server"
}

variable "private_key_location" {
  type        = string
  description = "The location of the user's private key on the local machine"
}

variable "public_key_location" {
  type        = string
  description = "The location of the user's public key on the location machine"
}
