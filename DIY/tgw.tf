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


# tgw firewall route table


# tgw egress route table


# associate the attachments with tgw route table


# tgw spoke routes


# tgw firewall routes


# tgw egress routes

