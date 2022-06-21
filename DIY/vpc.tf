# spoke vpc a definition
# subnet is can be referenced using the following
# module.spoke_vpc_a.all_subnets["subnet_a_workload"]
# module.spoke_vpc_a.all_subnets["subnet_a_tgw"]
module "spoke_vpc_a" {
  source         = "../modules/vpc"
  vpc_cidr_block = "10.1.0.0/16"
  vpc_name       = "spoke_vpc_a"

  subnets = [
    {
      az         = "ap-southeast-1a",
      name       = "subnet_a_workload",
      cidr_block = "10.1.1.0/24"
    },
    {
      az         = "ap-southeast-1a",
      name       = "subnet_a_tgw",
      cidr_block = "10.1.0.0/28"
    }
  ]
}

# spoke vpc b definition
# subnet is can be referenced using the following
# module.spoke_vpc_b.all_subnets["subnet_b_workload"]
# module.spoke_vpc_b.all_subnets["subnet_b_tgw"]
module "spoke_vpc_b" {
  source         = "../modules/vpc"
  vpc_cidr_block = "10.2.0.0/16"
  vpc_name       = "spoke_vpc_b"

  subnets = [
    {
      az         = "ap-southeast-1a",
      name       = "subnet_b_workload",
      cidr_block = "10.2.1.0/24"
    },
    {
      az         = "ap-southeast-1a",
      name       = "subnet_b_tgw",
      cidr_block = "10.2.0.0/28"
    }
  ]
}

# inspection vpc c definition
# subnet is can be referenced using the following
# module.inspection_vpc_c.all_subnets["inspection_tgw_a"]
# module.inspection_vpc_c.all_subnets["inspection_firewall_a"]
# module.inspection_vpc_c.all_subnets["inspection_tgw_b"]
# module.inspection_vpc_c.all_subnets["inspection_firewall_b"]
module "inspection_vpc_c" {
  source         = "../modules/vpc"
  vpc_cidr_block = "100.64.0.0/16"
  vpc_name       = "inspection_vpc_c"

  subnets = [
    {
      az         = "ap-southeast-1a",
      name       = "inspection_tgw_a",
      cidr_block = "100.64.0.0/28"
    },
    {
      az         = "ap-southeast-1a",
      name       = "inspection_firewall_a",
      cidr_block = "100.64.0.16/28"
    },
    {
      az         = "ap-southeast-1b",
      name       = "inspection_tgw_b",
      cidr_block = "100.64.0.32/28"
    },
    {
      az         = "ap-southeast-1b",
      name       = "inspection_firewall_b",
      cidr_block = "100.64.0.48/28"
    },
  ]
}

# egress vpc d definition
# subnet is can be referenced using the following
# module.egress_vpc_d.all_subnets["egress_tgw_a"]
# module.egress_vpc_d.all_subnets["egress_public_a"]
# module.egress_vpc_d.all_subnets["egress_tgw_b"]
# module.egress_vpc_d.all_subnets["egress_public_b"]
module "egress_vpc_d" {
  source         = "../modules/vpc"
  vpc_cidr_block = "10.10.0.0/16"
  vpc_name       = "egress_vpc_d"

  subnets = [
    {
      az         = "ap-southeast-1a",
      name       = "egress_tgw_a",
      cidr_block = "10.10.0.0/28"
    },
    {
      az         = "ap-southeast-1a",
      name       = "egress_public_a",
      cidr_block = "10.10.1.0/24"
    },
    {
      az         = "ap-southeast-1b",
      name       = "egress_tgw_b",
      cidr_block = "10.10.0.16/28"
    },
    {
      az         = "ap-southeast-1b",
      name       = "egress_public_b",
      cidr_block = "10.10.2.0/24"
    },
  ]
}

# IGW for egress vpc
resource "aws_internet_gateway" "egress_vpc_igw" {
  vpc_id = module.egress_vpc_d.vpc_id

  tags = {
    Name = "egress_vpc_igw"
  }
}

# Create 2 EIP for 2 NatGW
resource "aws_eip" "egress_vpc_nat_gw_eip_a" {
  tags = {
    Name = "egress_vpc_nat_gw_eip_a"
  }
}

resource "aws_eip" "egress_vpc_nat_gw_eip_b" {
  tags = {
    Name = "egress_vpc_nat_gw_eip_b"
  }
}

# NAT GW for egress vpc public subnet
# attach it to subnet egress_public_a and egress_public_b
resource "aws_nat_gateway" "egress_vpc_nat_gw_a" {
  depends_on    = [aws_internet_gateway.egress_vpc_igw, module.egress_vpc_d.all_subnets]
  allocation_id = aws_eip.egress_vpc_nat_gw_eip_a.id
  subnet_id     = module.egress_vpc_d.all_subnets["egress_public_a"].id
  tags = {
    Name = "egress_vpc_nat_gw_a"
  }
}

resource "aws_nat_gateway" "egress_vpc_nat_gw_b" {
  depends_on    = [aws_internet_gateway.egress_vpc_igw, module.egress_vpc_d.all_subnets]
  allocation_id = aws_eip.egress_vpc_nat_gw_eip_b.id
  subnet_id     = module.egress_vpc_d.all_subnets["egress_public_b"].id
  tags = {
    Name = "egress_vpc_nat_gw_b"
  }
}

### Route definition from here
## Spoke VPC A Route
# Spoke VPC A Route Table


# Attach all spoke vpc a subnets to the route table


## Spoke VPC B Route
# Spoke VPC B Route Table


# Attach all spoke vpc b subnets to the route table


## Inspection VPC Route
# Inspection VPC TGW Subnet A Route Table: AZ A


# Attach Inspection VPC TGW Subnet A to the route table


# Inspection VPC Firewall Subnet A Route Table


# Attach Inspection VPC Firewall Subnet A to the route table


# Inspection VPC TGW Subnet B Route Table: AZ B


# Attach Inspection VPC TGW Subnet B to the route table


# Inspection VPC Firewall Subnet B Route Table


# Attach Inspection VPC Firewall Subnet B to the route table


## Egress VPC Route
# Egress VPC Public Subnet A Route Table


# Attach Egress VPC Public Subnet A to the route table


# Egress VPC TGW Subnet A Route Table


# Attach Egress VPC TGW Subnet A to the route table


# Egress VPC route table configuration: AZ B
# Egress VPC Public Subnet B Route Table


# Attach Egress VPC Public Subnet B to the route table


# Egress VPC TGW Subnet B Route Table


# Attach Egress VPC TGW Subnet B to the route table

