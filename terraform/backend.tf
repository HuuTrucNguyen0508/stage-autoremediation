terraform {
  backend "s3" {
    bucket         = "truh1-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "truh1-terraform-locks"
    encrypt        = true
  }
}


