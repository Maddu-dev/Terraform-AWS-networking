#---------------networking/output.tf-----------------

output "vpc_id" {
  value = aws_vpc.maddu_vpc.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.maddu_rds_subnetgroup.*.name
}

output "db_security_group" {
  value = [aws_security_group.maddu_sg["rds"].id]
}

output "public_subnets" {
  value = aws_subnet.maddu_public_subnet.*.id
}

output "public_sg" {
  value = [aws_security_group.maddu_sg["public"].id]
}
