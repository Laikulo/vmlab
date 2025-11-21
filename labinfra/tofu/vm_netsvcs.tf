
resource "libvirt_volume" "netsvcs_boot" {
  pool = "default"
  name = "vmlab_netsvcs_boot"
  size = "21474836480" # 20 GiB
  format = "qcow2"
  base_volume_pool = "baseimgs"
  # TODO: Make a base image with pkgs already installed
  base_volume_name = "FreeBSD-14.3-RELEASE-amd64-BASIC-CLOUDINIT-ufs.qcow2"
}

resource "libvirt_cloudinit_disk" "netsvcs" {
  name = "netsvcs_cloudinit.iso"
  user_data = "#cloud-config"
}

resource "libvirt_domain" "netsvcs" {
  name = "vmlab:netsvcs"
  memory = "512"
  vcpu = 2
  running = false

  boot_device {
    dev = ["hd"]
  }

  disk {
    volume_id = libvirt_volume.netsvcs_boot.id
  }

  video {
    type = "none"
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  cloudinit = libvirt_cloudinit_disk.netsvcs.id

}
