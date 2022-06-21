# transit gateway definition
# attachments can be referenced by using the following
# module.transit_gateway.all_attachments["spoke_a_tgw_attachment]
# module.transit_gateway.all_attachments["spoke_b_tgw_attachment]
# module.transit_gateway.all_attachments["inspection_tgw_attachment]
# module.transit_gateway.all_attachments["egress_tgw_attachment]
module "transit_gateway" {
  source          = "../modules/tgw"
  tgw_name        = "central_tgw"
  tgw_description = "Transit Gateway NetworkFW Demo"

  attachments = [
    {
      name                                            = "spoke_a_tgw_attachment",
      vpc_id                                          = module.spoke_vpc_a.vpc_id,
      subnets                                         = [module.spoke_vpc_a.all_subnets["subnet_a_tgw"].id],
      appliance_mode_support                          = "disable",
      transit_gateway_default_route_table_association = false
    },
    {
      name                                            = "spoke_b_tgw_attachment",
      vpc_id                                          = module.spoke_vpc_b.vpc_id,
      subnets                                         = [module.spoke_vpc_b.all_subnets["subnet_b_tgw"].id],
      appliance_mode_support                          = "disable",
      transit_gateway_default_route_table_association = false
    },
    {
      name   = "inspection_tgw_attachment",
      vpc_id = module.inspection_vpc_c.vpc_id,
      subnets = [
        module.inspection_vpc_c.all_subnets["inspection_tgw_a"].id,
        module.inspection_vpc_c.all_subnets["inspection_tgw_b"].id
      ],
      appliance_mode_support                          = "enable",
      transit_gateway_default_route_table_association = false
    },
    {
      name   = "egress_tgw_attachment",
      vpc_id = module.egress_vpc_d.vpc_id,
      subnets = [
        module.egress_vpc_d.all_subnets["egress_tgw_a"].id,
        module.egress_vpc_d.all_subnets["egress_tgw_b"].id
      ],
      appliance_mode_support                          = "disable",
      transit_gateway_default_route_table_association = false
    }
  ]
}

## Transit Gateway Route Table
# tgw spoke route table
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = module.transit_gateway.tgw_id

  tags = {
    Name = "spoke_rt"
  }
}

# tgw firewall route table
resource "aws_ec2_transit_gateway_route_table" "firewall_rt" {
  transit_gateway_id = module.transit_gateway.tgw_id

  tags = {
    Name = "firewall_rt"
  }
}

# tgw egress route table
resource "aws_ec2_transit_gateway_route_table" "egress_rt" {
  transit_gateway_id = module.transit_gateway.tgw_id

  tags = {
    Name = "egress_rt"
  }
}

# associate the attachments with tgw route table
resource "aws_ec2_transit_gateway_route_table_association" "spoke_a_tgw_rt_association" {
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["spoke_a_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_b_tgw_rt_association" {
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["spoke_b_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "inspection_vpc_c_tgw_rt_association" {
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["inspection_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.firewall_rt.id
}

resource "aws_ec2_transit_gateway_route_table_association" "egress_vpc_d_tgw_rt_association" {
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["egress_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress_rt.id
}

# tgw spoke routes
resource "aws_ec2_transit_gateway_route" "spoke_inspection_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["inspection_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

# tgw firewall routes
resource "aws_ec2_transit_gateway_route" "firewall_spoke_a_route" {
  destination_cidr_block         = "10.1.0.0/16"
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["spoke_a_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.firewall_rt.id
}

resource "aws_ec2_transit_gateway_route" "firewall_spoke_b_route" {
  destination_cidr_block         = "10.2.0.0/16"
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["spoke_b_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.firewall_rt.id
}

resource "aws_ec2_transit_gateway_route" "firewall_egress_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["egress_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.firewall_rt.id
}

# tgw egress routes
resource "aws_ec2_transit_gateway_route" "egress_default_route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.transit_gateway.all_attachments["inspection_tgw_attachment"].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress_rt.id
}