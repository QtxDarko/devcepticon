# resource "aws_network_interface_sg_attachment" "bastion" {
#   count = var.cluster_config.access_from_bastion ? 1 : 0

#   security_group_id    = module.eks.cluster_primary_security_group_id
#   network_interface_id = data.aws_instance.bastion.network_interface_id
# }
