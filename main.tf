terraform {
  required_version = ">= 1.6.0"
}

resource "null_resource" "run_local_script" {
  triggers = {
    module_path = path.module
  }

  provisioner "local-exec" {
    command     = "bash ${self.triggers.module_path}/boot/start.sh"
    interpreter = ["/bin/bash", "-c"]
  }

#  To destroy all kubernetes estructure uncommente this code and run - tofu destroy -auto-approve
  provisioner "local-exec" {
    when        = destroy
    command     = "bash ${self.triggers.module_path}/boot/cleanup.sh"
    interpreter = ["/bin/bash", "-c"]
  }
}

