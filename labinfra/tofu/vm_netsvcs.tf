
resource "libvirt_volume" "netsvcs_boot" {
  pool = "default"
  name = "vmlab_netsvcs_boot"
  capacity = "21474836480" # 20 GiB
  format = "qcow2"
  backing_store = {
    # TODO: Figure out a way to get from pool
    path = "/var/lib/libvirt/images/baseimgs/vmlab:netsvcs"
    format = "qcow2"
  }
}

resource "libvirt_cloudinit_disk" "netsvcs" {
  name = "vmlab_netsvcs_cloudinit"
  meta_data = "hostname: 'netsvcs.lab'"
  user_data = <<-ENDUSER
    #cloud-config
    network:
      version: 2
      ethernets:
        - match:
            macaddress: '02:12:32:10:00:01'
          addresses:
            - 10.123.21.5
    ssh_authorized_keys:
      - "${trimspace(tls_private_key.mgmt_ssh_key.public_key_openssh)}"
    ENDUSER
}

resource "libvirt_volume" "netsvcs_cloudinit" {
  pool = "default"
  name = "vmlab_netsvcs_cloudinit"
  format = "iso"
  create = {
    content = {
      url = libvirt_cloudinit_disk.netsvcs.path
    }
  }
}

resource "libvirt_domain" "netsvcs" {
  name = "vmlab:netsvcs"
  memory = "512"
  unit = "MiB"
  vcpu = 1

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
    boot_devices = ["hd"]
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
        pool = libvirt_volume.netsvcs_boot.pool
        volume = libvirt_volume.netsvcs_boot.name
      }
    },{
      device = "cdrom"
      target = { dev = "sdb" }
      source = {
        pool = libvirt_volume.netsvcs_cloudinit.pool
        volume = libvirt_volume.netsvcs_cloudinit.name
      }
    }]
    interfaces = [{
      model = "virtio"
      mac = "02:12:32:10:00:01"
      type = "network"
      source = {
        network = "vmlab"
      }
    }]
  }

}
