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
variable "dev_instance_type" {}
variable "dev_ami" {}
variable "public_key_path" {}
variable "key_name" {}
variable "domain_name" {}

