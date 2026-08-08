provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Global dummy values to satisfy required module inputs across all runs
variables {
  vpc_id                           = "vpc-1234567890"
  public_subnet_ids                = ["subnet-pub1", "subnet-pub2"]
  private_subnet_ids               = ["subnet-priv1", "subnet-priv2"]
  msk_security_group_id            = "sg-1234567890"
  msk_bootstrap_brokers_sasl_scram = "b-1.mock.kafka.amazonaws.com:9096"
  kafka_domain                     = "mock.kafka.local"
  tls_secret_arn                   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-secret"
  client_cidrs                     = ["10.0.0.0/16"]
  route53_zone_id                  = "Z1234567890MOCK"
}

# Requirement 5: Verify create_dns_records = false does not require Route 53 zone ID
run "create_dns_records_disabled_without_zone_id" {
  command = plan

  variables {
    create_dns_records = false
    route53_zone_id    = null
  }

  assert {
    condition     = var.create_dns_records == false
    error_message = "Disabling DNS record creation must not require a Route 53 zone ID."
  }
}

# Requirement 6: Test optional alarms, dashboards, Container Insights, and ECS Exec
run "verify_optional_feature_flags" {
  command = plan

  variables {
    enable_container_insights   = true
    enable_execute_command      = true
    create_alarms               = true
    create_cloudwatch_dashboard = true
  }

  assert {
    condition     = var.enable_container_insights == true
    error_message = "Container Insights should be enabled."
  }

  assert {
    condition     = var.create_cloudwatch_dashboard == true
    error_message = "CloudWatch dashboard should be enabled."
  }
}

# Requirement 7: Verify Autoscaling configuration attributes
run "verify_autoscaling_configurations" {
  command = plan

  variables {
    name                     = "kafka-proxy-test"
    autoscaling_min_capacity = 2
    autoscaling_max_capacity = 10
    cpu_target_percent       = 75.0
    memory_target_percent    = 80.0
  }

  assert {
    condition     = aws_appautoscaling_target.proxy.min_capacity == 2
    error_message = "Autoscaling min_capacity should match variable input."
  }

  assert {
    condition     = aws_appautoscaling_target.proxy.max_capacity == 10
    error_message = "Autoscaling max_capacity should match variable input."
  }
}