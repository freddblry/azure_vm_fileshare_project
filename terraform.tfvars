# You generally don't need to touch this file for CI deploys.
project_name   = "azurevm"
location       = "francecentral"
vm_size        = "Standard_B1s"
admin_username = "devops"
fileshare_name = "projects"

address_space  = "10.20.0.0/16"
subnet_prefix  = "10.20.1.0/24"
