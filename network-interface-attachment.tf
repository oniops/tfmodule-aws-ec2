# Additional ENI attachments (primary ENI uses `primary_network_interface` block on aws_instance)
resource "aws_network_interface_attachment" "this" {
  for_each = var.create ? var.additional_network_interfaces : {}

  instance_id          = aws_instance.this[0].id
  network_interface_id = each.value.network_interface_id
  device_index         = each.value.device_index
  network_card_index   = each.value.network_card_index
}
