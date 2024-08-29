resource "local_file" "firewall" {
content  = "foo"
filename = "${path.module}/file.txt"
}