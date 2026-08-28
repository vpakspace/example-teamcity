output "teamcity_server" {
  value = {
    external_ip = yandex_compute_instance.teamcity_server.network_interface.0.nat_ip_address
    internal_ip = yandex_compute_instance.teamcity_server.network_interface.0.ip_address
    url         = "http://${yandex_compute_instance.teamcity_server.network_interface.0.nat_ip_address}:8111"
  }
}

output "teamcity_agent" {
  value = {
    external_ip = yandex_compute_instance.teamcity_agent.network_interface.0.nat_ip_address
    internal_ip = yandex_compute_instance.teamcity_agent.network_interface.0.ip_address
  }
}

output "nexus" {
  value = {
    external_ip = yandex_compute_instance.nexus.network_interface.0.nat_ip_address
    internal_ip = yandex_compute_instance.nexus.network_interface.0.ip_address
    url         = "http://${yandex_compute_instance.nexus.network_interface.0.nat_ip_address}:8081"
  }
}

output "ansible_inventory_hint" {
  description = "Готовая строка для inventory ansible (в образе AlmaLinux пользователь по умолчанию — almalinux)"
  value       = "nexus-01 ansible_host=${yandex_compute_instance.nexus.network_interface.0.nat_ip_address} ansible_user=almalinux"
}
