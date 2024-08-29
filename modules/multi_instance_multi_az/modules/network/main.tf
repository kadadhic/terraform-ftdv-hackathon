resource "local_file" "network" {
content  = "foo"
filename = "${path.module}/file.txt"
}