terraform {
  cloud {
    organization = "jdebo-automation"
    workspaces {
      name = "tf-serverless-emr"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

provider "random" {}

locals {
  name = "mba"
}
data "aws_caller_identity" "current" {}

# data "aws_vpc" "controltower" {
#   filter {
#     name   = "tag:Name"
#     values = ["*controltower*"] #replace if you aren't using control tower
#   }
# }

# # Grab all the public subnet ids
# data "aws_subnets" "controltower" {
#   filter {
#     name   = "tag:Name"
#     values = ["*Public*"] # update for you subnets
#   }
#   depends_on = [
#     data.aws_vpc.controltower
#   ]
# }

# Base EMR Studio needed to run EMR Serverless Applications
module "emr_studio_sso" {
  source = "terraform-aws-modules/emr/aws//modules/studio"


  name                = "${local.name}-studio"
  description         = "EMR Studio using SSO authentication"
  auth_mode           = "SSO"
  default_s3_location = "s3://${module.s3_bucket.s3_bucket_id}/complete"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  # SSO Mapping
  session_mappings = {
    admin_user = {
      identity_type = "USER"
      identity_id   = var.user_identity
    }
  }

  service_role_name        = "${local.name}-complete-service"
  service_role_path        = "/complete/"
  service_role_description = "EMR Studio complete service role"
  service_role_tags        = { service = true }
  service_role_s3_bucket_arns = [
    module.s3_bucket.s3_bucket_arn,
    "${module.s3_bucket.s3_bucket_arn}/complete/*}"
  ]

  service_role_statements = {
    # glue_assume = {
    #   sid     = "emrAssume"
    #   actions = ["sts:AssumeRole"]
    #   principals {
    #     type        = "Service"
    #     identifiers = ["glue.amazonaws.com"]
    #   }
    # },
    glue = {
      sid    = "GlueandWorkspace"
      effect = "Allow"
      actions = [
        "glue:GetDatabase",
        "glue:CreateDatabase",
        "glue:GetDataBases",
        "glue:CreateTable",
        "glue:GetTable",
        "glue:UpdateTable",
        "glue:DeleteTable",
        "glue:GetTables",
        "glue:GetPartition",
        "glue:GetPartitions",
        "glue:CreatePartition",
        "glue:BatchCreatePartition",
        "glue:GetUserDefinedFunctions",
        "elasticmapreduce:*", # Editor Roles
      ]
      resources = ["*"]
    },
    emr_samples = {
      sid    = "ReadAccessForEMRSamples"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      resources = [
        "arn:aws:s3:::*.elasticmapreduce",
        "arn:aws:s3:::*.elasticmapreduce/*"
      ]
    },
    all = {
      sid       = "All"
      effect    = "Allow"
      actions   = ["*"]
      resources = ["*"]
    }
  }
  # User role
  user_role_name        = "${local.name}-complete-user"
  user_role_path        = "/complete/"
  user_role_description = "EMR Studio complete user role"
  user_role_tags        = { user = true }
  user_role_s3_bucket_arns = [
    module.s3_bucket.s3_bucket_arn,
    "${module.s3_bucket.s3_bucket_arn}/complete/*}"
  ]
  user_role_statements = {
    all = {
      sid       = "All"
      effect    = "Allow"
      actions   = ["*"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_role" "glue_service" {
  name               = "GlueServiceRole-MBA"
  assume_role_policy = data.aws_iam_policy_document.glue_assume.json
}

# resource "aws_iam_role" "emr_user" {
#   name               = "EMRUserRole-MBA"
#   assume_role_policy = data.aws_iam_policy_document.emr_assume.json
# }

data "aws_iam_policy_document" "glue_assume" {
  statement {
    sid     = "emrAssume"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_service" {
  statement {
    sid    = "ReadAccessForEMRSamples"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*.elasticmapreduce",
      "arn:aws:s3:::*.elasticmapreduce/*"
    ]
  }

  statement {
    sid    = "FullAccessToOutputBucket"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::emr-backend-*", # isolate access to EMR buckets
      "arn:aws:s3:::emr-backend-*/*"
    ]
  }
  statement {
    sid    = "GlueCreateAndReadDataCatalog"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:CreateDatabase",
      "glue:GetDataBases",
      "glue:CreateTable",
      "glue:GetTable",
      "glue:UpdateTable",
      "glue:DeleteTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "glue_service" {
  name   = "GlueServicePolicy"
  role   = aws_iam_role.glue_service.id
  policy = data.aws_iam_policy_document.glue_service.json
}

# resource "aws_iam_role_policy" "emr_user" {
#   name   = "EMRAdminUserPolicy"
#   role   = aws_iam_role.emr_user.id
#   policy = data.aws_iam_policy_document.emr_user.json
# }

# resource "aws_iam_policy" "emr_admin" {
#   name   = "EMRAdminSessionPolicy"
#   policy = data.aws_iam_policy_document.emr_user.json
# }

resource "aws_emrserverless_application" "spark" {
  name          = "spark"
  release_label = "emr-6.6.0"
  type          = "spark"
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> v3.0"

  bucket_prefix = "${local.name}-emr-"

  # Allow deletion of non-empty bucket
  # Example usage only - not recommended for production
  force_destroy = true

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_security_group" "this" {
  name        = "emr"
  description = "Allow EMR traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = module.vpc.vpc_cidr_block
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = module.vpc.vpc_cidr_block
  from_port   = -1
  ip_protocol = -1
  to_port     = -1
}