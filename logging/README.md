per..

https://banzaicloud.com/docs/one-eye/logging-operator/quickstarts/example-s3/

need to.. 
create aws key secret in argo ns

run 

```
kubectl apply -f logging.yaml
kubectl apply -f flow_argo.yaml
kubectl apply -f output_argo.yaml
```
this will set up the logging in logging ns plus the rest in argo ns and will commence saving argo server, controller logs to the appropriate dir. 
BUT it doesn't save logs for workflow jobs run in argo ns!!

