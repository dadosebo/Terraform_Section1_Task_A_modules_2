module "vpc" {
  source = "./modules/networking"
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    name       = "VPC-local-modules"
  }



  subnet_config = {
    subnet_1 = {
      cidr_block = "10.0.0.0/24"
      az         = "eu-central-1a"
      public     = true
    }

    subnet_2 = {
      cidr_block = "10.0.1.0/24"
      az         = "eu-central-1a"
      public     = false
    }
  }
}
