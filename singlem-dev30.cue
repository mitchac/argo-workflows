apiVersion: "argoproj.io/v1alpha1"
kind:       "Workflow"
metadata: {
	generateName: "singlem-"
	namespace:    "argo"
}
spec: {
	securityContext: {
		runAsNonRoot: true
		runAsUser:    8737 //; any non-root user
		fsGroup:      8737
	}
	serviceAccountName: "argo"
	volumeClaimTemplates: [{
		metadata: name: "workdir"
		spec: {
			accessModes: ["ReadWriteOnce"]
			resources: requests: storage: "13Gi"
		}
	}]
	entrypoint: "output-artifact-gcs-example"
	ttlStrategy: {
		secondsAfterCompletion: 3600 // Time to live after workflow is completed, replaces ttlSecondsAfterFinished
		secondsAfterSuccess:    3600 // Time to live after workflow is successful
		secondsAfterFailure:    3600
	} // Time to live after workflow fails
	arguments: {
		parameters: [{
			name:  "SRA_accession_num"
			value: "ERR2535307"
		}]
	}
	templates: [{
		name: "output-artifact-gcs-example"
		inputs: {
			parameters: [{
				name:  "SRA_accession_num"
				value: "{{workflow.parameters.SRA_accession_num}}"
			}]
			artifacts: [{
				name: "my-art"
				path: "/my-artifact"
				gcs: {
					bucket: "bowerbird-testing-home"
					key:    "bowerbird"
				}
			}]
		}
		container: {
			name:  "singlem-gather"
			image: "gcr.io/maximal-dynamo-308105/singlem:0.13.2-dev30.e97d171"
			env: [{
				name:  "TMPDIR"
				value: "/mnt/vol"
			}]
			command: ["sh", "-c"]
			args: [
				" cd /mnt/vol; python /kingfisher-download/bin/kingfisher get -r {{inputs.parameters.SRA_accession_num}} --output-format-possibilities sra --guess-aws-location --hide-download-progress -m 'aws-http' && ls && /singlem/bin/singlem pipe --sra-files {{inputs.parameters.SRA_accession_num}}.sra --archive_otu_table {{inputs.parameters.SRA_accession_num}}.unannotated.singlem.json --threads 1 --singlem-metapackage /mpkg --no-assign-taxonomy && ls /mnt/vol ",
			]

			volumeMounts: [{
				name:      "workdir"
				mountPath: "/mnt/vol"
			}]
			resources: requests: {
				memory: "3600Mi"
				cpu:    1
			}
		}
		nodeSelector: purpose: "workflow-jobs"
		tolerations: [{
			key:      "reserved-pool"
			operator: "Equal"
			value:    "true"
			effect:   "NoSchedule"
		}]
		outputs: artifacts: [{
			name: "out-art"
			path: "/mnt/vol/{{workflow.parameters.SRA_accession_num}}.unannotated.singlem.json"
			gcs: {
				bucket: "bowerbird-testing-home"
				key:    "bowerbird/{{workflow.parameters.SRA_accession_num}}.unannotated.singlem.json"
			}
		}]
	}]
}
