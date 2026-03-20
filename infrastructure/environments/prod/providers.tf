locals {
  default_tags = {
    app  = "violet"
    env  = var.environment_name
    repo = "https://github.com/danwiltshire/violet"
  }
}

provider "aws" {
  profile = "admin"
  region  = "eu-west-2"
  alias   = "prod_eu_west_2"

  default_tags {
    tags = local.default_tags
  }
}
