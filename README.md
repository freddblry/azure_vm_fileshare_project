# Terraform Azure VM + Azure Files + GitHub Actions (One‑click)

Déploie une VM Ubuntu sur Azure avec montage **automatique** d’un **Azure File Share** dans `/Projects`, le tout via **Terraform** et **GitHub Actions**.
Le *state* Terraform est stocké dans un **backend Azure** créé automatiquement par le workflow.

## ⚡️ Déploiement en un clic

1. **Créer le secret GitHub `AZURE_CREDENTIALS`**
   - Sur votre machine Azure CLI :
     ```bash
     SUBSCRIPTION_ID="<votre-subscription-id>"
     az ad sp create-for-rbac            --name "github-actions-terraform"            --role "Contributor"            --scopes "/subscriptions/${SUBSCRIPTION_ID}"            --sdk-auth
     ```
     Copiez la sortie JSON dans **Settings → Secrets and variables → Actions → New repository secret** sous le nom **`AZURE_CREDENTIALS`**.

   > Astuce : Si vous voulez que le workflow puisse aussi créer les conteneurs du compte de stockage de backend via Azure AD au lieu des clés, accordez au SP le rôle **Storage Blob Data Contributor** sur ce compte. Ici, on utilise la **clé** du compte de stockage pour éviter des rôles supplémentaires.

2. **Lancer le workflow `Deploy Azure VM (Terraform)`**
   - Allez dans **Actions → Deploy Azure VM (Terraform) → Run workflow**. C’est tout.

3. **Récupérer les infos de sortie**
   - Le job affiche notamment l’IP publique de la VM et le chemin SMB du partage.

4. **Détruire l’environnement**
   - **Actions → Destroy Azure VM (Terraform) → Run workflow**.

---

## Ce qui est déployé

- **Resource Group** (ex: `azurevm-xxxxxx-rg`)
- **Réseau** (VNet + Subnet) + **NSG** ouvrant **SSH (22)**
- **IP Publique**, **NIC**
- **Storage Account** + **Azure File Share** (monté dans `/Projects`)
- **VM Ubuntu 22.04 LTS** avec **cloud-init** :
  - installe `cifs-utils`
  - crée `/etc/smbcredentials/<storage>.cred`
  - ajoute une entrée `/etc/fstab`
  - monte automatiquement le partage dans `/Projects`

> L’accès SSH est activé **par mot de passe**. Le mot de passe admin est **généré automatiquement** par le workflow et injecté via la variable `TF_VAR_admin_password` (il n’est pas loggé en clair par Terraform).

## Backend distant Azure (Terraform state)

Le workflow crée automatiquement :
- **Resource Group** : `tfstate-rg` (région `francecentral`)
- **Storage Account** : nom **déterministe** basé sur le repo (`tfstate<hash>`)
- **Container** : `tfstate`
- Le *state* est stocké dans `terraform.tfstate`.

## Variables utiles

Voir `variables.tf` et `terraform.tfvars`. Valeurs par défaut :
```hcl
project_name   = "azurevm"
location       = "francecentral"
vm_size        = "Standard_B1s"
admin_username = "devops"
fileshare_name = "projects"
address_space  = "10.20.0.0/16"
subnet_prefix  = "10.20.1.0/24"
```

**Ne pas** renseigner `admin_password` dans le dépôt : il est fourni par CI via `TF_VAR_admin_password`.

## Utilisation locale (optionnel)

```bash
# 1) Authentification Azure (via az cli)
az login
az account set --subscription "<SUBSCRIPTION_ID>"

# 2) Créer manuellement le backend si besoin (ou laisser le workflow s'en charger)
#    puis exportez ARM_ACCESS_KEY avant terraform init
#    (remplacez les noms par ceux créés par le workflow)
export ARM_ACCESS_KEY="<clé_du_storage_account_backend>"

terraform init       -backend-config="resource_group_name=tfstate-rg"       -backend-config="storage_account_name=tfstate<hash>"       -backend-config="container_name=tfstate"       -backend-config="key=terraform.tfstate"

# 3) Déployer
export TF_VAR_admin_password="$(openssl rand -base64 24)"
terraform apply -auto-approve
```

## Sécurité

- Le mot de passe VM est généré à chaque déploiement par le workflow.
- L’accès au partage Azure Files utilise la **clé** du compte de stockage (écrite dans `/etc/smbcredentials/...` côté VM).
- Le port ouvert est **22/tcp** (SSH). Restreignez-le si nécessaire (IP source) dans `main.tf`.

## Fichiers fournis

- `main.tf`, `variables.tf`, `terraform.tfvars`
- `.github/workflows/deploy.yml`, `.github/workflows/destroy.yml`
- `scripts/clean.sh`
- `README.md`

---

Bon déploiement ! 🚀
