resource "tls_private_key" "mgmt_ssh_key" {
	algorithm = "RSA"
	rsa_bits = 4096
}

resource "local_sensitive_file" "mgmt_ssh_key" {
	filename = "${path.module}/id_rsa_mgmt"
	content = tls_private_key.mgmt_ssh_key.private_key_openssh
}

resource "local_file" "mgmt_ssh_pubkey" {
	filename = "${path.module}/id_rsa_mgmt.pub"
	content = tls_private_key.mgmt_ssh_key.public_key_openssh
}
