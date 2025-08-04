variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  description = "Name of the key pair for EC2 login"
  default     = "your-keypair-name" # Change this to your actual key pair
}

variable "cluster_name" {
  default = "trend-cluster"
}
