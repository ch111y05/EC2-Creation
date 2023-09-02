# Outputs
output "private_subnet_id" {
  description = "The ID of the created private subnet."
  value       = aws_subnet.hashi_private_subnet.id
}

output "public_subnet_id" {
  description = "The ID of the created private subnet."
  value       = aws_subnet.hashi_public_subnet.id
}

output "aws_internet_gateway_id" {
  description = "The ID of the Internet Gateway used for the public subnet."
  value       = aws_internet_gateway.hashi_internet_gateway.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway used for the private subnet."
  value       = aws_nat_gateway.hashi_nat_gateway.id
}

output "aws_security_group" {
  description = "The ID of the security used for the EC2 instance."
  value       = aws_security_group.hashi_sg.id
}

output "dev_node_instance_id" {
  description = "The ID of the created EC2 instance."
  value       = aws_instance.dev_node.id
}

output "ami_id" {
  description = "AMI ID depends on the instance type and region in which you're launching your stack. And IDs can change regularly, such as when an AMI is updated with software updates."
  value       = aws_ami_from_instance.default.id
}
