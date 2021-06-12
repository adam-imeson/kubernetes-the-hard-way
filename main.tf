# Configure the AWS Provider
provider "aws" {
  region  = var.region
  profile = terraform.workspace
}
