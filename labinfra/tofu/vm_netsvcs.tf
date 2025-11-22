
resource "libvirt_volume" "netsvcs_boot" {
  pool = "default"
  name = "vmlab_netsvcs_boot"
  size = "21474836480" # 20 GiB
  format = "qcow2"
  base_volume_pool = "baseimgs"
  base_volume_name = "vmlab:netsvcs"
}

resource "libvirt_cloudinit_disk" "netsvcs" {
  name = "netsvcs_cloudinit.iso"
  meta_data = "hostname: 'netsvcs.lab'"
  user_data = <<-ENDUSER
    #cloud-config
    networking:
      version: 2
      ethernets:
        match:
          macaddress: '02:12:32:10:00:01'
        addresses:
          - 10.123.21.5
    ssh_authorized_keys:
      - "${tls_private_key.mgmt_ssh_key.public_key_openssh}"
    ENDUSER
}

resource "libvirt_domain" "netsvcs" {
  name = "vmlab:netsvcs"
  memory = "512"
  vcpu = 1
  
  cpu {
    mode = "host-passthrough"
  }

  #machine = "q35"

  boot_device {
    dev = ["hd"]
  }

  disk {
    volume_id = libvirt_volume.netsvcs_boot.id
    scsi = true
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  

  network_interface {
    network_id = libvirt_network.vmlab.id
    hostname = "netsvcs.lab"
    addresses = ["10.123.21.5"]
    mac = "02:12:32:10:00:01"
    wait_for_lease = false
  }


  cloudinit = libvirt_cloudinit_disk.netsvcs.id
}
