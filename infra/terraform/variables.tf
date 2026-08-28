variable "sa_key_file" {
  description = "Путь до authorized key сервисного аккаунта"
  type        = string
  default     = "~/.authorized_key.json"
}

variable "cloud_id" {
  type    = string
  default = "b1gvj00hq3o6suge2haf"
}

variable "folder_id" {
  type    = string
  default = "b1gabvo7h0vqf8vkt52s"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "ssh_public_key_file" {
  description = "Публичный ключ, который кладётся на все ВМ пользователю yc-user"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "teamcity_version" {
  description = "Тег Docker-образов jetbrains/teamcity-server и jetbrains/teamcity-agent"
  type        = string
  default     = "2026.1.3"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

# Внутренние адреса фиксируем: агент обращается к серверу по внутреннему IP
variable "ip_teamcity_server" {
  type    = string
  default = "10.10.0.10"
}

variable "ip_teamcity_agent" {
  type    = string
  default = "10.10.0.11"
}

variable "ip_nexus" {
  type    = string
  default = "10.10.0.20"
}
