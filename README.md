# ☁️ Azure VM + File Share via GitHub Actions & Terraform

Ce projet déploie une **VM Ubuntu** sur Azure avec un **File Share monté automatiquement dans `/Projects`**, via **Terraform** et **GitHub Actions**.

---

## 🔐 Configuration Azure

1. Créez une App Registration avec `az` :
```bash
az ad sp create-for-rbac --name github-deployer --role Contributor --sdk-auth
```

2. Copiez le JSON retourné.

3. Dans GitHub → Settings → Secrets → Actions :
   - Ajoutez un secret nommé **`AZURE_CREDENTIALS`**
   - Collez le JSON en valeur

---

## 🚀 Déploiement

Lancez le workflow GitHub :

- `🚀 Deploy Azure VM + File Share`

Il exécutera automatiquement :
- `terraform init`
- `terraform apply`

---

## 💣 Destruction

Lancez le workflow :

- `💣 Destroy Azure VM + File Share`

---

## 📁 Structure

```
azure_vm_fileshare_project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── modules/
│       ├── storage/
│       └── vm/
├── .github/workflows/
│   ├── deploy.yml
│   └── destroy.yml
└── scripts/
    └── clean.sh
```

---

## 📌 Remarques

- Utilise un **backend distant Azure** (Blob Storage)
- Le File Share est monté dans **`/Projects`**
- Authentification via `azure/login@v1` et `AZURE_CREDENTIALS` uniquement
