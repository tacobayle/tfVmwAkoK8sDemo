cd ~/tfVmwAkoK8sDemo ; $(terraform output -json | jq -r .Destroy_command_wo_tf.value) ; terraform destroy -auto-approve ; cd ~ ; rm -fr tfVmwAkoK8sDemo ; git clone https://github.com/tacobayle/tfVmwAkoK8sDemo ; cd tfVmwAkoK8sDemo ; terraform init ; terraform apply -auto-approve