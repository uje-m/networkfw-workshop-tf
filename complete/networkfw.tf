# rule group definition
resource "aws_networkfirewall_rule_group" "icmp_alert_stateful_rule_group" {
  capacity = 100
  name     = "icmp-alert"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "ALERT"
        header {
          direction        = "ANY"
          protocol         = "ICMP"
          destination      = "ANY"
          source           = "ANY"
          destination_port = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword = "sid:1"
        }
      }
    }
  }

  tags = {
    Name = "icmp-alert"
  }
}

resource "aws_networkfirewall_rule_group" "domain_allow_stateful_rule_group" {
  capacity = 100
  name     = "domain-allow"
  type     = "STATEFUL"
  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["10.0.0.0/8"]
        }
      }
    }
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = [".amazon.com", ".google.com"]
      }
    }
  }

  tags = {
    Name = "domain-allow"
  }
}

resource "aws_networkfirewall_rule_group" "suricata_detect_non_TLS_over_TLS_ports" {
  capacity = 10
  name     = "Suricata-detect-non-TLS-over-TLS-Ports"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_string = <<EOF
alert tcp any any <> any 443 (msg:"SURICATA Port 443 but not TLS"; flow:to_server,established; app-layer-protocol:!tls; sid:2271003; rev:1;)
      EOF
    }
  }

  tags = {
    Name = "Suricata-detect-non-TLS-over-TLS-Ports"
  }
}

resource "aws_networkfirewall_rule_group" "emerging_user_agents_rule_group" {
  capacity = 300
  name     = "emerging-user-agents"
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = ["10.0.0.0/8"]
        }
      }
    }
    rules_source {
      rules_string = file("emerging-user-agents.rules")
    }
  }

  tags = {
    Name = "emerging-user-agents-rule-group"
  }
}

# policy to contain rule groups
resource "aws_networkfirewall_firewall_policy" "inspection_firewall_policy" {
  name = "inspection-firewall-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_allow_stateful_rule_group.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.icmp_alert_stateful_rule_group.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.suricata_detect_non_TLS_over_TLS_ports.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.emerging_user_agents_rule_group.arn
    }
  }

  tags = {
    Name = "inspection-firewall-policy"
  }
}

# the nfw itself
resource "aws_networkfirewall_firewall" "inspection_firewall" {
  name                = "inspection-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.inspection_firewall_policy.arn
  vpc_id              = module.inspection_vpc_c.vpc_id

  subnet_mapping {
    subnet_id = module.inspection_vpc_c.all_subnets["inspection_firewall_a"].id
  }

  subnet_mapping {
    subnet_id = module.inspection_vpc_c.all_subnets["inspection_firewall_b"].id
  }

  tags = {
    Name = "inspection-firewall"
  }
}

# logging configuration
resource "aws_cloudwatch_log_group" "networkfw_alert_log_group" {
  name = "/aws/networkfw_workshop_group/alert"
}

resource "aws_cloudwatch_log_group" "networkfw_flow_log_group" {
  name = "/aws/networkfw_workshop_group/flow"
}

resource "aws_networkfirewall_logging_configuration" "networkfw_logging_configuration" {
  firewall_arn = aws_networkfirewall_firewall.inspection_firewall.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.networkfw_alert_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.networkfw_flow_log_group.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
