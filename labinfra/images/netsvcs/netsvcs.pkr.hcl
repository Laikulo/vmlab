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
    name = "vmlab:netsvcs:v2"
    source {
      type = "backing-store"
      pool = "baseimgs"
      volume = "freebsd-15.0-cloudinit-ufs"
    }
    capacity = "8G"
    alias = "artifact"
  }
  
  volume {
    bus = "sata"
    source {
      type = "cloud-init"
      # FreeBSD uses nuageinit
      user_data = format("#cloud-config\n%s", yamlencode({
        ssh_authorized_keys = [
          data.sshkey.packer.public_key
        ],
        users = null,
        package_updatge = true,
        package_upgrade = true,
        packages = [
          "kea",
          "tftp-hpa",
          "yadifa",
          "augeas",
          "doas",
          "rsync",
          "darkhttpd",
          "fusefs-squashfuse"
        ],
        runcmd = [
          "rm -f /etc/hostid",
          "touch /firstboot",
          "sysrc firstboot_freebsd_update_enable= ifconfig_DEFAULT=",
          "rm /var/cache/nuageinit/runcmds",
          "shutdown -p +1"
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
    communicator = "none"
  }

  # shutdown_mode = "agent" # This won't work, so it is the same as 'none'
  shutdown_timeout = "600s"
}


build {
  sources = [ "sources.libvirt.netsvcs" ]
}
