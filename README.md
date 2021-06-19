Learning kubernetes via https://github.com/kelseyhightower/kubernetes-the-hard-way. This repo sets up the infra in AWS via Terraform so I don't lose track of what I am doing.

Build with `terraform apply`. You will need credentials for an AWS account.

Be aware that this will (as of this writing) spin up 6 m5.xlarge instances, which will collectively cost you $27.65 per day that you leave them running. 

Also be aware that this stack is insecure because it's meant for learning and experimentation. Anyone with access to your tfstate will be able to not only log into all of the stack's instances, but also issue themselves certs using your CA.
