provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}

# Global dummy values to satisfy required module inputs across all guardrail tests
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

# Requirement 1: Reject unrestricted 0.0.0.0/0 client access by default
run "reject_unrestricted_client_cidrs_by_default" {
  command = plan

  variables {
    client_cidrs                    = ["0.0.0.0/0"]
    allow_unrestricted_client_cidrs = false
  }

  expect_failures = [
    aws_lb.kafka,
  ]
}

# Requirement 2: Verify explicit unrestricted-CIDR escape hatch
run "allow_unrestricted_client_cidrs_escape_hatch" {
  command = plan

  variables {
    client_cidrs                    = ["0.0.0.0/0"]
    allow_unrestricted_client_cidrs = true
  }

  assert {
    condition     = length(var.client_cidrs) > 0
    error_message = "Unrestricted client CIDR should be allowed when allow_unrestricted_client_cidrs is true."
  }
}

# Requirement 3: Reject mutable container image tags by default
run "reject_mutable_image_tag_by_default" {
  command = plan

  variables {
    kroxylicious_image      = "kroxylicious/proxy:latest"
    allow_mutable_image_tag = false
  }

  expect_failures = [
    aws_lb.kafka,
  ]
}

# Requirement 4: Verify explicit mutable-tag escape hatch
run "allow_mutable_image_tag_escape_hatch" {
  command = plan

  variables {
    kroxylicious_image      = "kroxylicious/proxy:latest"
    allow_mutable_image_tag = true
  }

  assert {
    condition     = var.kroxylicious_image == "kroxylicious/proxy:latest"
    error_message = "Mutable image tags should be permitted when allow_mutable_image_tag is true."
  }
}