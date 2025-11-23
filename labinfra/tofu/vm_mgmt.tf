
resource "libvirt_volume" "mgmt_boot" {
  pool = "default"
  name = "vmlab_mgmt_boot"
  capacity = "21474836480" # 20 GiB
  format = "qcow2"
}

resource "libvirt_domain" "mgmt" {
  name = "vmlab:mgmt"

  running = true

  memory = "2048"
  unit = "MiB"
  vcpu = 2

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true,
    apic = true
  }


  os = {
    type = "hvm"
    arch = "x86_64"
    machine = "q35"
    boot_devices = ["hd","network"]
  }

  devices = {
    consoles = [{
      type = "pty"
      target_type = "serial"
      target_port = 0
    }]
    disks = [{
      target = { dev = "vda" }
      source = {
        pool = libvirt_volume.mgmt_boot.pool
        volume = libvirt_volume.mgmt_boot.name
      }
    }]
    interfaces = [{
      model = "virtio"
      mac = "02:12:32:10:00:02"
      type = "network"
      source = {
        network = "vmlab"
      }
    }]
  }

  lifecycle {
    ignore_changes = [
      devices.consoles[0].source_path
    ]
  }

}
