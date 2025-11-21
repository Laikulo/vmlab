resource "libvirt_network" "vmlab" {
	name = "vmlab"
	autostart = "true"
	bridge = "vmlab"
	mode = "none"
}
