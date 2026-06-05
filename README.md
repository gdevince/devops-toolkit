# devops-toolkit

Scripts and tools I use daily for Azure, AKS and CI/CD.

A collection of reusable scripts, manifests and pipeline templates built from real-world experience with Azure infrastructure, Kubernetes workloads and Windows-based deployments.

---

## Contents

### [`windows-iis/`](./windows-iis)
PowerShell deployment scripts for Windows Services and IIS applications. Covers artifact download from Azure Blob Storage, MD5 checksum verification, backup, stop/start lifecycle and rollback support.

### [`kubernetes/`](./kubernetes)
Kubernetes manifests for operational tasks. Includes automated Dapr mTLS certificate rotation via CronJob with RBAC least-privilege configuration.

### [`pipelines/`](./pipelines)
Azure DevOps pipeline templates for CI/CD automation.

---

## Tech Stack

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat&logo=kubernetes&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoftazure&logoColor=white)
![Dapr](https://img.shields.io/badge/Dapr-0D2192?style=flat&logo=dapr&logoColor=white)
![Helm](https://img.shields.io/badge/Helm-0F1689?style=flat&logo=helm&logoColor=white)

---

## License

[MIT](./LICENSE)
