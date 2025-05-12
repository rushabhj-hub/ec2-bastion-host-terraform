variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "public subnet"
  type        = string
}
 variable "ami_id" {
    description = " The AMI ID to use for the EC2 instance"
    type        = string
   
 }


 variable "ec2_key" {
    description = " The key name to use for the EC2 instance"
    type        = string
   
 }