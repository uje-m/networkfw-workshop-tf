variable "vpc_cidr_block" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "subnets" {
  type = list(object({
    az         = string,
    name       = string,
    cidr_block = string
  }))
}
