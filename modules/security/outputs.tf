output "alb_sg_id"       { value = aws_security_group.alb.id }
output "api_sg_id"       { value = aws_security_group.api.id }
output "orders_sg_id"    { value = aws_security_group.orders.id }
output "inventory_sg_id" { value = aws_security_group.inventory.id }
output "rds_sg_id"       { value = aws_security_group.rds.id }
output "redis_sg_id"     { value = aws_security_group.redis.id }
