# Provider principal: regiao DR (us-west-2)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SolidaryTech"
      Environment = "DR" # diferente de "Production" do primary p/ filtrar custos
      CostCenter  = "NGO-Core"
      ManagedBy   = "Terraform"
      Repository  = var.repository
    }
  }
}
