output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "all_subnets" {
  value = aws_subnet.subnets
}