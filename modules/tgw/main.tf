resource "aws_ec2_transit_gateway" "tgw" {
  description = var.tgw_description

  tags = {
    Name = var.tgw_name
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "attachments" {
  for_each                                        = { for attachments in var.attachments : attachments.name => attachments }
  subnet_ids                                      = each.value.subnets
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = each.value.vpc_id
  appliance_mode_support                          = each.value.appliance_mode_support
  transit_gateway_default_route_table_association = each.value.transit_gateway_default_route_table_association

  tags = {
    Name = each.value.name
  }
}