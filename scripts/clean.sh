#!/bin/bash
echo "🧹 Nettoyage des fichiers Terraform locaux..."
cd terraform
rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
echo "✅ Nettoyage terminé."
