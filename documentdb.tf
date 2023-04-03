resource "aws_docdb_cluster_instance" "cluster_instances" {
  identifier         = "mba-docdb-cluster"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier = "mba-docdb-cluster"
  db_subnet_group_name = aws_docdb_subnet_group.this.name
  master_username    = "mba-admin"
  master_password    = random_password.docdb_pass.result
}

resource "aws_docdb_subnet_group" "this" {
  name       = "main"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "MBA docdb subnet group"
  }
}

resource "aws_secretsmanager_secret" "docdb_pass" {
  name = "mba-docdb-admin"
}

resource "aws_secretsmanager_secret_version" "docdb_pass" {
  secret_id = aws_secretsmanager_secret.docdb_pass.id
  secret_string = random_password.docdb_pass.result
}

resource "random_password" "docdb_pass" {
  length = 12
}