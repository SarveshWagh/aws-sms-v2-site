# AWS variables
ami = "ami-022409c69e757cfd3"
instance-type = "t3.xlarge"
vol-size = 80
vol-type = "gp2"
key-pair = "my-aws-fresh-key"
no_of_nics = 2
eip_config = {
    create_eip  = true
    existing_allocation_ids = [] # Set create_eip as 'true', if this TF code has to create it. Else, set it to 'false' and add the existing EIPs to the list.
}
security_group_config = {
  create_slo_sg     = true
  create_sli_sg     = true
  existing_slo_sg_id = ""    # Do not add any value here if 'create_slo_sg' is 'true'. Else, change 'create_slo_sg' as 'false' and provide existing Security group IDs for SLO interface
  existing_sli_sg_id = ""    # Do not add any value here if 'create_sli_sg' is 'true'. Else, change 'create_sli_sg' as 'false' and provide existing Security group  IDs for SLI interface
}
subnet-ids-for-slo-nics = ["subnet-0819a3b0c42b21904", "subnet-01abd643a6a763cd2", "subnet-0ee6bf9db8dfa900f"]
subnet-ids-for-sli-nics = ["subnet-0897e7b0d7bb382af", "subnet-05fc064e405a92ada", "subnet-0d87ff8b9306d8e0f"]
sg-name = "my-sg-group"
vpc-id = "vpc-059dabf7405169983"

# XC variables
smsv2-site-name = "spiderman-aws-site"
num_of_ce_nodes = 3
# api_p12_file     = "./f5-consult.console.ves.volterra.io.api-creds.p12"
# api_url          = "https://f5-consult.console.ves.volterra.io/api"
# virtual-site-name = "azure-sweden-virtual-site"
# kbskb


