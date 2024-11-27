# EIP
resource "aws_eip_association" "this" {
  count         = var.create && var.eip_allocation_id != null ? 1 : 0
  instance_id   = aws_instance.this[0].id
  allocation_id = var.eip_allocation_id
  depends_on = [
    aws_instance.this
  ]
}
