1. Create VPC with CIDR block - define in file => /networking.tf
2. create subnets (private / public) - define in file => /networking.tf

3. After cmd terraform apply, automatically will be created VPC, subnets. 
4. Following by IGW for public subnet, NAT for private subnet
