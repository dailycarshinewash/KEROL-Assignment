# KEROL-Assignment
KEROL-Assignment
-------------------------------------------------------------------------
Implementation of the assignment:

Create the terraform deployment to host a stateless application containerised here:
https://hub.docker.com/r/nginxdemos/hello/

Create the architecture diagram for the deployment using:
https://github.com/mingrammer/diagrams

If applicable depends on your chosen approach:

1. Ensure application is deployed behind a load balancer.
2. On the point of the load balancer the application needs to be HA.
3. Ensure that the network hosting of the web application is secured.
4. If application is hosted in a VM build as well the infrastructure for safely access it via ssh.
5. Make use of service accounts where applicable.
6. Depending on how your application is hosted, propose options for securing access to the web application itself.
7. Create all the public/private networks needed to secure unwanted access from the Internet to the infrastructure hosting the web application.

Use a repository on www.github.com to manage all the code parts of the assignment and provide instructions on how to consume the repository.

--------------------------------------------------------------------

1. Architecture Diagram.

Run Following cmd to create Architecture Diagram,

python Architecture-Diagram\architecture-diagram.py

----------------------------------------------------------------------

2. AWS Infrasturcture

Run Following cmds to create infrastructure,

terraform init
terraform plan
terraform apply --auto-approve

Run Following cmd to Delete infrastructure,

terraform destroy --auto-approve