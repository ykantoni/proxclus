# proxclus

A hardened Ubuntu + RKE2 Kubernetes cluster on a single Proxmox VE host,
split across three repositories by lifecycle and pinned here as submodules.

| Submodule    | Repository                                   | Owns                                                                 | Applied by |
| ------------ | -------------------------------------------- | -------------------------------------------------------------------- | ---------- |
| `vm-infra/`  | https://github.com/ykantoni/vm-infra         | golden images (Packer), Proxmox VMs, RKE2, Cilium CNI, Argo CD, the two root Applications | GitHub Actions on a self-hosted runner: plan on PR, approved apply on `main` |
| `k8s-infra/` | https://github.com/ykantoni/k8s-infra        | LB-IPAM pool, Sealed Secrets, Longhorn, metrics-server, CNPG operator, kube-prometheus-stack, NVIDIA GPU operator | Argo CD, `root-k8s-infra` |
| `k8s-apps/`  | https://github.com/ykantoni/k8s-apps         | Ollama + Open WebUI, Postgres                                         | Argo CD, `root-k8s-apps` |

Also here, outside any pipeline: `troubleshooting-agents/`, LangGraph
troubleshooting agents with a React GUI and a Headlamp plugin; see its
README.

## How it fits together

```
 vm-infra (Terraform, self-hosted runner)
   packer ──► templates 9100/9101
   rke2-config ──► proxmox-vm ──► rke2-cluster ──► cilium ──► argocd
                                                              │
                        ┌─────────────────────────────────────┴──────────────┐
                        ▼                                                    ▼
          root-k8s-infra (argocd ns)                          root-k8s-apps (argocd-apps ns)
          project k8s-infra: cluster-wide                     project k8s-apps: own namespaces only
          waves: sealed-secrets → lb-ipam → longhorn          no waves; retry until k8s-infra's
                 → metrics/cnpg/gpu → prometheus              CRDs and StorageClasses exist
```

Argo CD tracks `main` of k8s-infra and k8s-apps directly; it never reads this
repository. The submodule pointers here are just a record of a known-good
combination of the three.

## Bootstrap from nothing

1. Proxmox host prepared per `vm-infra/proxmox-host/` and
   `vm-infra/runner/README.md` (self-hosted runner, secrets, `proxmox`
   environment).
2. `vm-infra`: `vm-templates/import-ubuntu-cloud-image.sh` once, then the
   Packer workflow (or `just t-create`).
3. `vm-infra`: merge to `main` and approve the apply (or `just apply` on the
   runner host). Argo CD comes up and starts syncing k8s-infra and k8s-apps.
4. First build only: `just seal-key-backup`, then `just seal-cert` into
   `k8s-infra/pub-cert.pem` and `k8s-apps/pub-cert.pem`, and commit the
   SealedSecrets those repos' READMEs list.

After that, day-to-day changes are PRs to whichever repository owns the
thing being changed.

## Working with the submodules

```bash
git clone --recurse-submodules https://github.com/ykantoni/proxclus.git
just sync        # move every submodule to the tip of its main
just status      # submodule commits + Argo CD application status
```

Commit the updated pointers here after verifying a combination works.
