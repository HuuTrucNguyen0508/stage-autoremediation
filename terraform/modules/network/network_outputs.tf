output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_az2_id" {
  description = "ID of the public subnet in AZ2"
  value       = aws_subnet.public_az2.id
}

output "private_subnet_id" {
  description = "ID of the private subnet in AZ1"
  value       = aws_subnet.private.id
}

output "private_subnet_az2_id" {
  description = "ID of the private subnet in AZ2"
  value       = aws_subnet.private_az2.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = aws_nat_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
} 
