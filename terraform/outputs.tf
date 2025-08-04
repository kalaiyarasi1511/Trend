output "eks_cluster_name" {
  value = aws_eks_cluster.trend_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.trend_cluster.endpoint
}

output "jenkins_ec2_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}
