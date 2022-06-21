variable "tgw_description" {
  type = string
}

variable "tgw_name" {
  type = string
}

variable "attachments" {
  type = list(object({
    name                                            = string,
    vpc_id                                          = string,
    subnets                                         = list(string),
    appliance_mode_support                          = string,
    transit_gateway_default_route_table_association = bool
  }))
}
