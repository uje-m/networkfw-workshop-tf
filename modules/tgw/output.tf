output "tgw_id" {
  value = aws_ec2_transit_gateway.tgw.id
}

output "all_attachments" {
  value = aws_ec2_transit_gateway_vpc_attachment.attachments
}