output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.trend_cluster.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.trend_cluster.endpoint
}

output "jenkins_ec2_public_ip" {
  description = "The public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_ec2.public_ip
}

