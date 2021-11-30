package create_argo_batch

merged_templates: [ for acc in _data.sra_accessions {
	{
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Workflow"
		metadata: {
			generateName: "singlem-"
			namespace:    "argo"
			labels: nickname: "\(_data.summary)"
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
					resources: requests: storage: "\(((__div((7000+acc["mbytes"]), 1))+1)*1)Mi"
				}
			}]
			entrypoint: "singlem-task"
			ttlStrategy: {
				secondsAfterCompletion: 3600 // Time to live after workflow is completed, replaces ttlSecondsAfterFinished
				secondsAfterSuccess:    3600 // Time to live after workflow is successful
				secondsAfterFailure:    3600
			} // Time to live after workflow fails
			arguments: {
				parameters: [{
					name:  "SRA_accession_num"
					value: acc["acc"]
				}]
			}
			templates: [{
				name: "singlem-task"
				inputs: {
					parameters: [{
						name:  "SRA_accession_num"
						value: acc["acc"]
					}]
//					artifacts: [{
//						name: "my-art"
//						path: "/my-artifact"
//						if _cloud_provider == "aws" {
//							s3: _cloud_configs.aws.storage
//						}
//						if _cloud_provider == "gcp" {
//							gcs: _cloud_configs.gcp.storage
//						}
//
//					}]
				}
				archiveLocation: {
					archiveLogs: true
					if _cloud_provider == "aws" {
						s3: {
							endpoint: _cloud_configs.aws.storage.endpoint
							bucket:   _cloud_configs.aws.storage.bucket
							key:      "\(_cloud_configs.aws.storage.key)/{{workflow.parameters.SRA_accession_num}}"
						}
					}
					if _cloud_provider == "gcp" {
                                                gcs: {
                                                        bucket: _cloud_configs.gcp.storage.bucket
                                                        key:    "\(_cloud_configs.gcp.storage.key)/{{workflow.parameters.SRA_accession_num}}"
                                                }
                                        }
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
						//memory: "3600Mi"
						memory: "\((__div((1200+2*(__div(acc["mbases"], 1000))), 256))*256)Mi"
						cpu:    "500m"
					}
				}
				_nodeSelector: purpose: "workflow-jobs"
				tolerations: [{
					key:      "reserved-pool"
					operator: "Equal"
					value:    "true"
					effect:   "NoSchedule"
				}]
				outputs: artifacts: [{
					name: "out-art"
					path: "/mnt/vol/{{workflow.parameters.SRA_accession_num}}.unannotated.singlem.json"
					if _cloud_provider == "aws" {
						s3: {
							endpoint: _cloud_configs.aws.storage.endpoint
							bucket:   _cloud_configs.aws.storage.bucket
							key:      "\(_cloud_configs.aws.storage.key)/{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.unannotated.singlem.json"
						}
					}
					if _cloud_provider == "gcp" {
						gcs: {
							bucket: _cloud_configs.gcp.storage.bucket
							key:    "\(_cloud_configs.gcp.storage.key)/{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.unannotated.singlem.json"
						}
					}
				}]
			}]
		}
	}
}]
