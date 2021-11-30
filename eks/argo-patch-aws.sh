kubectl -n argo patch \
  configmap workflow-controller-configmap \
-p "$(cat argo-patch-aws.yaml)"
