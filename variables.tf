variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "code_bucket_name" {}
variable "db_instance_class" {}
variable "db_engine_version" {}
variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
variable "vpc_cidr" {}
variable "cidrs" {
  type = "map"
}

