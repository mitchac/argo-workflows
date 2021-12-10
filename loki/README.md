install loki stack per..
https://www.youtube.com/watch?v=UM8NiQLZ4K0
nb i also added taints and tolerations for promtail into the values file.
at the appropriate point in the video install this using the following command..
```
helm install loki-stack grafana/loki-stack --values loki-stack-values.yaml -n loki --create-namespace
```
