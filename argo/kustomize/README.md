try kustomize for customising the vanilla argo workflows install.yaml to be ready to run on cluster. 

I'm using the approach documented here.. 

https://www.densify.com/kubernetes-tools/kustomize

to build run.. 
```
kubectl kustomize ./
```
..and to apply to the cluster run..
```
kubectl apply -k  overlays/prod
```

