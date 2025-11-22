resource "libvirt_network" "vmlab" {
	name = "vmlab"
	autostart = "true"
	bridge = "vmlab"
	mode = "none"
  addresses = [ "10.123.21.0/24" ]
}
