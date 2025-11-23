packer {
  required_plugins {
    libvirt = {
      source = "github.com/thomasklein94/libvirt"
      version = ">= 0.5.0"
    }
    sshkey = {
      source = "github.com/ivoronin/sshkey"
      version = ">= 1.1.0"
    }
  }
}

data "sshkey" "packer" {
}

source "libvirt" "netsvcs" {
  libvirt_uri = "qemu:///system"
  vcpu = 1
  memory = 512

  volume {
    bus = "virtio"
    
    pool = "baseimgs"
    name = "vmlab:netsvcs"
    source {
      type = "backing-store"
      pool = "baseimgs"
      volume = "freebsd-14.3-cloudinit"
    }
    capacity = "8G"
    alias = "artifact"
  }
  
  volume {
    bus = "sata"
    source {
      type = "cloud-init"
      # FreeBSD uses nuageinit
      # This version also has no support for runcmd, or even pkgs, so we use it to get SSH going.
      # It also doesn't handle scripts on iso9660, because they are not executable
      # yamlencode is used here (even though packer docs reccomend against) because nuageinit can't parse the json this makes
      # Also, consider using a tempalte yaml, since a stray newline gets in there somewhere
      user_data = format("#cloud-config\n%s", yamlencode({
        ssh_authorized_keys = [
          data.sshkey.packer.public_key
        ]
      }))
    }
  }

  network_interface {
    type = "managed"
    network = "default"
  }

  network_address_source = "lease"
  
  communicator {
    communicator = "ssh"
    ssh_username = "freebsd"
    ssh_private_key_file = data.sshkey.packer.private_key_path
  }

  shutdown_mode = "acpi"
}


build {
  sources = [ "sources.libvirt.netsvcs" ]
  provisioner "shell" {
    inline = [
      "su root -c 'pkg update && pkg upgrade -y && pkg install -y kea tftp-hpa yadifa augeas doas rsync caddy'",
      "su root -c 'echo \"permit nopass freebsd as root\" > /usr/local/etc/doas.conf'",
      ":> ~/.ssh/authorized_keys",
      "doas rm -f /etc/hostid",
      "doas touch /firstboot",
      "doas sysrc firstboot_freebsd_update_enable= ifconfig_DEFAULT="
    ]
  }
}
