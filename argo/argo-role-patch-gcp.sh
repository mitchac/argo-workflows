kubectl -n argo patch \
  role argo-role \
-p "$(cat argo-role-patch-gcp.yaml)"
