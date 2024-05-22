variable "aws_region" {
  description = "The AWS region where the resources will be created."
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  description = "The CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster."
  default     = "SkyEyeEksCluster"
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository."
  default     = "sky-eye-ecr-repository"
}

variable "db_instance_identifier" {
  description = "The identifier for the RDS PostgreSQL database instance."
  default     = "sky-eye-db-instance"
}

variable "db_instance_username" {
  description = "The username for the RDS PostgreSQL database."
  default     = "admin_user"
}

variable "db_instance_password" {
  description = "The password for the RDS PostgreSQL database."
  default     = "4dsqFWwEVTog" 
}

variable "redis_cluster_id" {
  description = "Id to assign the new cluster"
  default = "SkyEyeRedisCluster"
}

variable "public_key_path" {
  description = "Path to public key for ssh access"
  default     = "~/.ssh/id_rsa.pub"
}

variable "node_groups" {
  description = "Number of nodes groups to create in the cluster"
  default     = 1
}