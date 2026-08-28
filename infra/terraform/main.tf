data "yandex_compute_image" "coi" {
  family    = "container-optimized-image"
  folder_id = "standard-images"
}

data "yandex_compute_image" "almalinux" {
  family    = "almalinux-9"
  folder_id = "standard-images"
}

resource "yandex_vpc_network" "this" {
  name = "teamcity-net"
}

resource "yandex_vpc_subnet" "this" {
  name           = "teamcity-subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.subnet_cidr]
}

resource "yandex_vpc_security_group" "this" {
  name       = "teamcity-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "TeamCity web UI"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8111
  }

  ingress {
    protocol       = "TCP"
    description    = "Nexus web UI и maven-репозиторий"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8081
  }

  ingress {
    protocol       = "ICMP"
    description    = "ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "ANY"
    description       = "Трафик внутри группы: агент -> сервер, агент -> nexus"
    predefined_target = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    description    = "Весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  ssh_metadata = "yc-user:${trimspace(file(pathexpand(var.ssh_public_key_file)))}"
}

# ---------------------------------------------------------------------------
# TeamCity server: 4 vCPU / 4 GB, Container Optimized Image + jetbrains/teamcity-server
# ---------------------------------------------------------------------------
resource "yandex_compute_instance" "teamcity_server" {
  name        = "teamcity-server"
  hostname    = "teamcity-server"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 4
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.coi.id
      size     = 30
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    ip_address         = var.ip_teamcity_server
    nat                = true
    nat_ip_address     = yandex_vpc_address.teamcity.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.this.id]
  }

  metadata = {
    ssh-keys = local.ssh_metadata
    docker-compose = templatefile("${path.module}/files/tc-server-compose.yml", {
      teamcity_version = var.teamcity_version
    })
  }
}

# ---------------------------------------------------------------------------
# TeamCity agent: 2 vCPU / 4 GB, COI + jetbrains/teamcity-agent, SERVER_URL на сервер
# ---------------------------------------------------------------------------
resource "yandex_compute_instance" "teamcity_agent" {
  name        = "teamcity-agent"
  hostname    = "teamcity-agent"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.coi.id
      size     = 30
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    ip_address         = var.ip_teamcity_agent
    nat                = true
    security_group_ids = [yandex_vpc_security_group.this.id]
  }

  metadata = {
    ssh-keys = local.ssh_metadata
    docker-compose = templatefile("${path.module}/files/tc-agent-compose.yml", {
      teamcity_version = var.teamcity_version
      server_ip        = var.ip_teamcity_server
    })
  }

  depends_on = [yandex_compute_instance.teamcity_server]
}

# ---------------------------------------------------------------------------
# Nexus: 2 vCPU / 4 GB, AlmaLinux 9 (playbook из ДЗ ставит JDK 8 из rpm-репозиториев)
# ---------------------------------------------------------------------------
resource "yandex_compute_instance" "nexus" {
  name        = "nexus"
  hostname    = "nexus"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.almalinux.id
      size     = 30
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    ip_address         = var.ip_nexus
    nat                = true
    nat_ip_address     = yandex_vpc_address.nexus.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.this.id]
  }

  metadata = {
    ssh-keys = local.ssh_metadata
  }
}

# Статический адрес для TeamCity: динамический адрес попал в подсеть, недоступную
# из сети рабочей машины (TCP не проходит, ICMP идёт)
resource "yandex_vpc_address" "teamcity" {
  name = "teamcity-server-addr"

  external_ipv4_address {
    zone_id = var.zone
  }
}

resource "yandex_vpc_address" "nexus" {
  name = "nexus-addr"

  external_ipv4_address {
    zone_id = var.zone
  }
}
