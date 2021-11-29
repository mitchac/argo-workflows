import "k8s.io/api/core/v1"

services: [string]: v1.#Service

service: cuetorials: {
	apiVersion: "v1"
	kind:       "Service"
	metadata: {
		name:      "cuetorials"
		namespace: "websites"
		labels: app: "cuetorials"
	}
	spec: {
		selector: app: "cuetorials"
		type: "ClusterIP"
		ports: [{
			port:       80
			targetPort: 80
		}]
	}
}
