
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

resource "libvirt_volume" "netsvcs_srv" {
  pool = "default"
  name = "vmlab_netsvcs_srv"
  capacity = "109261619200" # 100 GiB
  format = "qcow2"
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
            - 10.123.21.1
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

  running = true

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
    disks = concat([
    {
      target = { dev = "vda" }
      source = {
        pool = libvirt_volume.netsvcs_boot.pool
        volume = libvirt_volume.netsvcs_boot.name
      }
    },
    {
      target = { dev = "vdb" }
      source = {
        pool = libvirt_volume.netsvcs_srv.pool
        volume = libvirt_volume.netsvcs_srv.name
      }
    },
    {
      device = "cdrom"
      target = { dev = "sdb" }
      source = {
        pool = libvirt_volume.netsvcs_cloudinit.pool
        volume = libvirt_volume.netsvcs_cloudinit.name
      }
    }],[
      for idx, path in var.squashes: {
        device = "disk",
        readonly = true
        target = { dev = local.squash_drives[idx] }
        source = {
          file = path
        }
    }])

    interfaces = [{
      model = "virtio"
      mac = "02:12:32:10:00:01"
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

  connection {
    type = "ssh"
    user = "freebsd"
    private_key = tls_private_key.mgmt_ssh_key.private_key_openssh
    host = "10.123.21.1"
  }

  provisioner "remote-exec" {
    inline = [
      "doas sysrc tftpd_enable=YES tftpd_flags=\"-s /srv/tftp -l\" kea_enable=YES ",
      "doas mkdir /srv",
      "doas -- sh -c 'echo /dev/gpt/srvdata /srv ufs rw 2 2 >> /etc/fstab'",
      "doas mount /srv",
    ]
  }

  provisioner "local-exec" {
    command = "./deploy-net-config noreload"
    working_dir = ".."
  }

  provisioner "remote-exec" {
    inline = [
      "doas service tftpd start",
      "sleep 20",
      "doas service kea start",
      # TODO: Figure out why kea doesn't stay running.
      # TODO: HTTP server for stage2
      # TODO: rework deploy-net-config to use rsync (since that is now available)
    ]
  }

}

locals {
  # I'm not about to admit how long I tried to make this a for expression
  squash_drives = [ 
    "vdc",
    "vdd",
    "vde",
    "vdf",
    "vdg",
    "vdh",
    "vdi",
    "vdj",
    "vdk",
    "vdj",
    "vdm",
  ]
}

