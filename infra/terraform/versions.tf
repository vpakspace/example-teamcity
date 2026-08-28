terraform {
  required_version = ">= 1.5"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.140"
    }
  }
}

provider "yandex" {
  service_account_key_file = pathexpand(var.sa_key_file)
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}
