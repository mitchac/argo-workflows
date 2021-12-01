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
					resources: requests: storage: "\(((__div((10000+acc["mbytes"]), 1))+1)*1)Mi"
				}
			}]
			entrypoint: "singlem-task"
			ttlStrategy: {
				secondsAfterCompletion: 3600   // Time to live after workflow is completed, replaces ttlSecondsAfterFinished
				secondsAfterSuccess:    3600   // Time to live after workflow is successful
				secondsAfterFailure:    604800 // 1 week
			} // Time to live after workflow fails
			arguments: {
				parameters: [{
					name:  "SRA_accession_num"
					value: acc["acc"]
				}]
			}
			templates: [{
				name: "singlem-task"
				retryStrategy: {
					limit:       "2"
					retryPolicy: "Always"
				}
				inputs: {
					parameters: [{
						name:  "SRA_accession_num"
						value: acc["acc"]
					}]
					//     artifacts: [{
					//      name: "my-art"
					//      path: "/my-artifact"
					//      if _cloud_provider == "aws" {
					//       s3: _cloud_configs.aws.storage
					//      }
					//      if _cloud_provider == "gcp" {
					//       gcs: _cloud_configs.gcp.storage
					//      }
					//
					//     }]
				}
				archiveLocation: {
					archiveLogs: true
					if _cloud_provider == "aws" {
						s3: {
							endpoint: _cloud_configs.aws.storage.endpoint
							bucket:   _cloud_configs.aws.storage.bucket
							key:      "\(_cloud_configs.aws.storage.key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}"
						}
					}
					if _cloud_provider == "gcp" {
						gcs: {
							bucket: _cloud_configs.gcp.storage.bucket
							key:    "\(_cloud_configs.gcp.storage.key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}"
						}
					}
				}
				container: {
					name:  "singlem"
					image: "gcr.io/maximal-dynamo-308105/singlem:0.13.2-dev31.e97d171"
					env: [{
						name:  "TMPDIR"
						value: "/mnt/vol"
					}]
					command: ["bash", "-c"]
					args: [
						"""
							echo Processing {{workflow.name}} {{inputs.parameters.SRA_accession_num}};
							cd /mnt/vol;
							kingfisher get -r {{inputs.parameters.SRA_accession_num}} --output-format-possibilities sra --guess-aws-location --hide-download-progress -m 'aws-http' &&
							ls -l && 
							/tmp/singlem/bin/singlem pipe --sra-files {{inputs.parameters.SRA_accession_num}}.sra --archive_otu_table >(gzip >{{inputs.parameters.SRA_accession_num}}.annotated.singlem.json.gz) --threads 1 --singlem-metapackage /mpkg
						""",
					]

					volumeMounts: [{
						name:      "workdir"
						mountPath: "/mnt/vol"
					}]
					resources: requests: {
						// convert mbases to gbases
						_gbases: div(acc["mbases"], 1000)
						// the fixed amount of ram
						_ram_buffer: 1800
						// the additional mb of ram we'll add per gbase in the sample
						_ram_mult: 20
						// calculate ram required
						_ram_reqd: _ram_buffer + _ram_mult*_gbases
						// convert this value to the nearest multiple of 256mb
						// this is a k8s requirement
						_ram_nearest_256_Mi: (div(_ram_reqd, 256) * 256)
						// add "Mi" and convert to string to 
						_ram_nearest_256_Mi_units: "\(_ram_nearest_256_Mi)Mi"
						memory:                    _ram_nearest_256_Mi_units
						cpu:                       "750m"
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
					path: "/mnt/vol/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
					archive:
						none: {} // Do not apply the argo default tar.gz since we are already gzipped and it is only 1 file
					if _cloud_provider == "aws" {
						s3: {
							endpoint: _cloud_configs.aws.storage.endpoint
							bucket:   _cloud_configs.aws.storage.bucket
							key:      "\(_cloud_configs.aws.storage.key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
						}
					}
					if _cloud_provider == "gcp" {
						gcs: {
							bucket: _cloud_configs.gcp.storage.bucket
							key:    "\(_cloud_configs.gcp.storage.key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
						}
					}
				}]
			}]
		}
	}
}]
