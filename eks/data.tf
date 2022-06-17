data "aws_vpcs" "public" {
  tags = {
    Scope = "Public"
  }
}

data "aws_security_groups" "sg_default" {
  filter {
    name = "vpc-id"
    values = [
      join("", data.aws_vpcs.public.ids)
    ]
  }

  filter {
    name = "group-name"
    values = [
      "default"
    ]
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = join("", data.aws_vpcs.public.ids)
}

data "aws_subnet" "public" {
  for_each = data.aws_subnet_ids.public.ids
  id       = each.value
}

data "aws_instance" "bastion" {
  filter {
    name = "tag:Name"
    values = [
      "EKS Bastion"
    ]
  }
}
