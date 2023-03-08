data "aws_caller_identity" "current" {}

data "aws_vpc" "controltower" {
  filter {
    name   = "tag:Name"
    values = ["*controltower*"] #replace if you aren't using control tower
  }
}

data "aws_subnet" "controltower" {
  vpc_id = data.aws_vpc.controltower.id
  filter {
    name   = "tag:Name"
    values = ["*Public*"] # update for you subnets
  }
  depends_on = [
    data.aws_vpc.controltower
  ]
}

resource "aws_emr_studio" "this" {
  auth_mode                   = "SSO"
  default_s3_location         = "s3://${aws_s3_bucket.this.bucket}/emr-studio"
  engine_security_group_id    = aws_security_group.this.id
  name                        = "mba-studio"
  service_role                = aws_iam_role.emr_service.arn
  subnet_ids                  = [data.aws_subnet.controltower.id]
  user_role                   = aws_iam_role.emr_service.arn
  vpc_id                      = data.aws_vpc.controltower.id
  workspace_security_group_id = aws_security_group.this.id
}

resource "aws_iam_role" "emr_service" {
  name               = "EMRServiceRole-MBA"
  assume_role_policy = data.aws_iam_policy_document.emr_assume.json

}
data "aws_iam_policy_document" "emr_assume" {
  statement {
    sid     = "emrAssume"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "emr_service" {
  statement {
    sid    = "ReadAccessForEMRSamples"
    effect = "Allow"
    action = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resource = [
      "arn:aws:s3:::*.elasticmapreduce",
      "arn:aws:s3:::*.elasticmapreduce/*"
    ]
  }

  statement {
    sid    = "FullAccessToOutputBucket"
    effect = "Allow"
    action = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resource = [
      "arn:aws:s3:::DOC-EXAMPLE-BUCKET",
      "arn:aws:s3:::DOC-EXAMPLE-BUCKET/*"
    ]
  }
  statement {
    sid    = "GlueCreateAndReadDataCatalog"
    effect = "Allow"
    action = [
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
      "glue:GetUserDefinedFunctions"
    ]
    resource = ["*"]
  }
}

resource "aws_iam_role_policy" "emr_service" {
  name   = "EMRServicePolicy"
  role   = aws_iam_role.emr_service.id
  policy = data.aws_iam_policy_document.emr_service.json
}

resource "aws_emrserverless_application" "spark" {
  name          = "spark"
  release_label = "emr-6.6.0"
  type          = "spark"
}

resource "aws_s3_bucket" "this" {
  bucket = "emr-backend-${data.aws_caller_identity.current.account_id}"

}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_security_group" "this" {
  name        = "emr"
  description = "Allow EMR traffic"
  vpc_id      = data.aws_vpc.controltower.id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = data.aws_subnet.controltower.cidr_block
  from_port   = 0
  ip_protocol = -1
  to_port     = 20000
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = data.aws_subnet.controltower.cidr_block
  from_port   = 0
  ip_protocol = -1
  to_port     = 20000
}