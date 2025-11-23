resource "libvirt_network" "vmlab" {
	name = "vmlab"
	autostart = "true"
	bridge = "vmlab"
	mode = "none"
  ips = [
    { address = "10.123.21.254", prefix = 24 }
  ]
}
