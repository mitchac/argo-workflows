kubectl -n argo patch \
  role argo-role \
-p "$(cat logs-patch-aws.yaml)"
