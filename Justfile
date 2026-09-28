# Umbrella tasks. Each submodule has its own Justfile for its own work
# (`just --justfile vm-infra/Justfile --working-directory vm-infra apply`).

github := "https://github.com/ykantoni"

# One-time: register the three repositories as submodules, once they exist
# on GitHub.
submodules-add:
    git submodule add -b main {{github}}/vm-infra.git vm-infra
    git submodule add -b main {{github}}/k8s-infra.git k8s-infra
    git submodule add -b main {{github}}/k8s-apps.git k8s-apps

# Move every submodule to the tip of its tracked branch (main).
sync:
    git submodule update --init --remote
    git submodule status

# Build or update the platform (VMs, RKE2, Cilium, Argo CD). Run on the
# self-hosted runner host, where vm-infra's Terraform state lives.
bootstrap:
    cd vm-infra && just apply

# Submodule commits and Argo CD's view of both pipelines.
status:
    git submodule status
    kubectl -n argocd get applications.argoproj.io
    kubectl -n argocd-apps get applications.argoproj.io
