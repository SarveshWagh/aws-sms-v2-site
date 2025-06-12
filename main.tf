# Write the terraform code as if you are manually creating the resources on AWS and XC
# On XC we need:
    # SMSv2 site object
    # SMSv2 site token
# On AWS we need:
    # One security group
    # One SSH key to sign in into the CE node.
    # One elastic IP
    # Two NICs [Network interface cards] - slo and sli
    # One CE node 
# On AWS, since this is brown field deployment, assuming VPC and subnets are created.

# =========================================================================================================
# XC resources
# =========================================================================================================

# Create SMSV2 site object on XC for AWS
resource "volterra_securemesh_site_v2" "aws-smsv2-site-object" {
  name = var.smsv2-site-name
  namespace = "system"
  # labels = {
  #   "myapp" = "sar-site"
  # }
  block_all_services = true
  logs_streaming_disabled = true
  aws {
    not_managed {}
  }
  # code: parameter = condition ? value if true : value if false
  disable_ha = var.num_of_ce_nodes == 1 ? true : false
  enable_ha = var.num_of_ce_nodes > 2 ? true : false
  re_select {
    geo_proximity = true
  }
}

# Create site token on XC for the site registration
resource "volterra_token" "aws-smsv2-site-token" {
  name = "${var.smsv2-site-name}-token"
  namespace = "system"
  type = 1
  site_name = volterra_securemesh_site_v2.aws-smsv2-site-object.name
  depends_on = [ volterra_securemesh_site_v2.aws-smsv2-site-object ]
}

# Create a virtual site
# resource "volterra_virtual_site" "vs-name" {
#     name = var.virtual-site-name
#     namespace = "wagh"
#     site_type = "CUSTOMER_EDGE"
#     site_selector {
#       expressions = ["myapp in (sar-site)"]
#     }
# }

# =========================================================================================================


# =========================================================================================================
# AWS resources
# =========================================================================================================

# Create SLO Security groups for SLO interfaces
resource "aws_security_group" "slo-sg" {
    count = var.security_group_config.create_slo_sg ? 1 : 0
    name = "${var.smsv2-site-name}-slo-sg"
    description = "Security group for SLO NICs, allow inbound and outbound traffic"
    vpc_id = var.vpc-id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Create SLI Security groups for SLI interfaces
resource "aws_security_group" "sli-sg" {
    count = var.no_of_nics == 2 && var.security_group_config.create_sli_sg ? 1 : 0
    name = "${var.smsv2-site-name}-sli-sg"
    description = "Security group for SLI NICs, allow inbound and outbound traffic"
    vpc_id = var.vpc-id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# Allocate/Create elastic IP
# No of EIPs is equal to no of nodes as the nodes will have minimum 1 nic which is SLO by default.
resource "aws_eip" "eips" {
  # Whether we should create EIP or not depends on the below code.
  # If 'create_eip' is 'true' then length has to be '0'
  # If 'create_eip' is 'false' then length has to be > '0'
  count = var.eip_config.create_eip && length(var.eip_config.existing_allocation_ids) == 0 ? var.num_of_ce_nodes : 0
  # code: Depending on the value 'count' receives, 'tags' will be iterated for 'Name', 'count' no of times.
  tags = {
    Name = "${var.smsv2-site-name}-slo-eip-${count.index+1}"
    }
}

# Create SLO network interface card [NICs] for the AWS CE node
# No of SLO interfaces always same as no of nodes.
# Depending on the no of nodes, we have to pass the SLO subnet IDs in terraform.tfvars file. So, that will be a list of strings
resource "aws_network_interface" "slo-nics" {
    count = var.num_of_ce_nodes
    # code: Depending on the value 'count' receives, 'subnet_id' will be iterated/populated, 'count' no of times.
    subnet_id = var.subnet-ids-for-slo-nics[count.index]
    # code: Depending on the value 'count' receives, 'tags' will be iterated for 'Name', 'count' no of times.
    tags = {
        Name = "${var.smsv2-site-name}-slo-nic-${count.index+1}"
    }
    security_groups = var.security_group_config.create_slo_sg ? [aws_security_group.slo-sg[0].id] : [var.security_group_config.existing_slo_sg_id]
    depends_on = [ aws_security_group.slo-sg ]
}

# Create SLI network interface card [NICs] for the AWS CE node
# SLI will come to picture only if no of NICs is 2 for a CE node.
# If NICs = 1 for a node, then, no SLI interfaces at all.
# Id NICs = 2 for a node, then, no of SLI interfaces is also same as no of nodes.
resource "aws_network_interface" "sli-nics" {
    # code: 'count' receives the value: 'var.num_of_ce_nodes' if 'var.no_of_nics == 2' 
    # code: 'count' receives the value: '0' if 'var.no_of_nics == 1'
    count = var.no_of_nics == 2 ? var.num_of_ce_nodes : 0
    # code: Depending on the value 'count' receives, 'subnet_id' will be iterated/populated, 'count' no of times.
    subnet_id = var.subnet-ids-for-sli-nics[count.index]
    # code: Depending on the value 'count' receives, 'tags' will be iterated for 'Name', 'count' no of times.
    tags = {
        Name = "${var.smsv2-site-name}-sli-nic-${count.index+1}"
    }
    security_groups = var.security_group_config.create_sli_sg ? [aws_security_group.sli-sg[0].id] : [var.security_group_config.existing_sli_sg_id]
    depends_on = [ aws_security_group.sli-sg ]
}

# Associate newly created elastic IP address with SLO NIC
resource "aws_eip_association" "associate_eip_with_slo-nics" {
  count = var.eip_config.create_eip && length(var.eip_config.existing_allocation_ids) == 0 ? var.num_of_ce_nodes : 0
  # code: Depending on the value 'count' receives, 'network_interface_id' and 'allocation_id' will be iterated, 'count' no of times.
  network_interface_id = aws_network_interface.slo-nics[count.index].id
  allocation_id = aws_eip.eips[count.index].id
  depends_on = [ aws_eip.eips, aws_network_interface.slo-nics ]
}

# Associate existing created elastic IP address with SLO NIC
resource "aws_eip_association" "associate_existing_eip_with_slo-nics" {
  count = var.eip_config.create_eip ? 0 : length(var.eip_config.existing_allocation_ids)
  # code: Depending on the value 'count' receives, 'network_interface_id' and 'allocation_id' will be iterated, 'count' no of times.
  network_interface_id = aws_network_interface.slo-nics[count.index].id
  allocation_id = aws_eip.eips[count.index].id
  depends_on = [ aws_eip.eips, aws_network_interface.slo-nics ]
}

# Create CE node on AWS
resource "aws_instance" "ce-node" {
  count = var.num_of_ce_nodes
  # code: Depending on the value 'count' receives, all below settings/configs will be iterated, 'count' no of times.
  #Name and tags

  # Application and OS Images (Amazon Machine Image) 
  ami = var.ami

  # Instance type
  instance_type = var.instance-type

  # Key pair (login) 
  key_name = var.key-pair
  # Network settings
  # Advanced network configuration
  # Attaching primary network interface or SLOs to the CE nodes.
  network_interface {
    network_interface_id = aws_network_interface.slo-nics[count.index].id
    device_index = 0
  }
  # Attaching secondary network interface or SLIs to the CE nodes if no of NICs is 2.
  # The below block comes to picture only when no of NICs is 2. We use 'dynamic' in place of 'if' condition in TF
  # In line 159 if var.no_of_nics is '2' then 'for_each' receives a list with one item as [1]. So, the network_interface block will be created once.
  dynamic network_interface {
    for_each = var.no_of_nics == 2 ? [1] : []
    content {
      network_interface_id = aws_network_interface.sli-nics[count.index].id
      device_index = 1
    }

  }
    
  # Storage (volumes)
  root_block_device {
    volume_size = var.vol-size
    volume_type = var.vol-type
  }

  # Advanced details
  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${volterra_token.aws-smsv2-site-token.id}
  owner: root
  permissions: '0644'
EOF
    depends_on = [ volterra_token.aws-smsv2-site-token ]
}

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# =========================================================================================================