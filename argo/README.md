use kustomize for customising the vanilla argo workflows install.yaml to be ready to run on cluster. 

Follow the approach documented here.. 

https://www.densify.com/kubernetes-tools/kustomize

First download the latest version of argo from the following url: 

https://github.com/argoproj/argo-workflows/releases/latest

You should then have the latest install.yaml in this directory i.e. to download, put the install.yaml from the releases page into the current directory.

To customise with kustomize..

to build run.. 
```
kubectl kustomize ./
```
create argo namespace
```
kubectl create ns argo
```
..and to apply to the cluster run..
```
kubectl apply -k ./ -n argo
```

