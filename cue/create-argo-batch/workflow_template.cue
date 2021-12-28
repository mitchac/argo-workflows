package create_argo_batch

import "list"

merged_templates: [ for acc in _data.sra_accessions {
	{
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Workflow"
		metadata: {
			generateName: "singlem-" + acc["acc_lowercase"] + "-"
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
				secondsAfterCompletion: 300  // Time to live after workflow is completed, replaces ttlSecondsAfterFinished
				secondsAfterSuccess:    300  // Time to live after workflow is successful
				secondsAfterFailure:    3600 // 3 hours
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
					limit:       "3"
					retryPolicy: "OnError"
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
							key:      "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}"
						}
					}
					if _cloud_provider == "gcp" {
						gcs: {
							bucket: _cloud_configs.gcp.storage.bucket
							key:    "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}"
						}
					}
				}
				container: {
					name:  "singlem"
					image: "public.ecr.aws/m5a0r7u5/singlem-wdl:0.13.2-dev37.e97d171"
					env: [{
						name:  "TMPDIR"
						value: "/mnt/vol"
					}]
					command: ["bash", "-c"]
					args: [
						// Delete .sra file first if it exists, in case of a rerun where there was only a partially complete download.
						"""
							echo Processing {{workflow.name}} {{inputs.parameters.SRA_accession_num}};
							cd /mnt/vol;
							rm -fv {{inputs.parameters.SRA_accession_num}}.sra;
							kingfisher get -r {{inputs.parameters.SRA_accession_num}} --output-format-possibilities sra --hide-download-progress -m aws-cp aws-http prefetch &&
							ls -l && 
							pidstat -r 5 -e bash -c '/tmp/singlem/bin/singlem pipe --sra-files {{inputs.parameters.SRA_accession_num}}.sra --archive_otu_table >(gzip >{{inputs.parameters.SRA_accession_num}}.annotated.singlem.json.gz) --threads 1 --singlem-metapackage /mpkg' |awk '{print $7}' |sort -rn |head -1 >max_rss
							export PIPELINE_EXITSTATUS=$?;
							rm -v {{inputs.parameters.SRA_accession_num}}.sra;
							exit $PIPELINE_EXITSTATUS							
						""",
					]

					volumeMounts: [{
						name:      "workdir"
						mountPath: "/mnt/vol"
					}]
					resources: {
						limits: {
							cpu: "950m"
							memory: "3584Mi"
						}
						requests: {
							// convert mbases to gbases
							_gbases: div(acc["mbases"], 1000)
							// the fixed amount of ram
							_ram_buffer: 512
							// the additional mb of ram we'll add per gbase in the sample
							_ram_mult: 60
							// calculate variable amount of ram
							_ram_variable: _ram_mult * _gbases
							// cap variable ram at 3000mb
							_ram_variable_capped: list.Sort([3000, _ram_variable], list.Ascending)[0]
							// calculate total ram required
							_ram_reqd: _ram_buffer + _ram_variable_capped
							// convert this value to the nearest multiple of 256mb
							// this is a k8s requirement
							_ram_nearest_256_Mi: (div(_ram_reqd, 256) * 256)
							// add "Mi" and convert to string to 
							_ram_nearest_256_Mi_units: "\(_ram_nearest_256_Mi)Mi"
							//memory:                    _ram_nearest_256_Mi_units
							memory:                    "1792Mi" 
							cpu:                       "950m"
						}}

				}
				if _node_restrictions == "yes" {
					nodeSelector: purpose: "workflow-jobs"
					tolerations: [{
						key:      "reserved-pool"
						operator: "Equal"
						value:    "true"
						effect:   "NoSchedule"
					}]
				}
				outputs: artifacts: [
					{
						name: "out-art"
						path: "/mnt/vol/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
						archive:
							none: {} // Do not apply the argo default tar.gz since we are already gzipped and it is only 1 file
						if _cloud_provider == "aws" {
							s3: {
								endpoint: _cloud_configs.aws.storage.endpoint
								bucket:   _cloud_configs.aws.storage.bucket
								key:      "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
							}
						}
						if _cloud_provider == "gcp" {
							gcs: {
								bucket: _cloud_configs.gcp.storage.bucket
								key:    "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
							}
						}
					},
					{
						name: "out-art2"
						path: "/mnt/vol/max_rss"
						archive:
							none: {} // Do not apply the argo default tar.gz since we are already gzipped and it is only 1 file
						if _cloud_provider == "aws" {
							s3: {
								endpoint: _cloud_configs.aws.storage.endpoint
								bucket:   _cloud_configs.aws.storage.bucket
								key:      "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/max_rss"
							}
						}
						if _cloud_provider == "gcp" {
							gcs: {
								bucket: _cloud_configs.gcp.storage.bucket
								key:    "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/max_rss"
							}
						}
					},
				]
			}]
	}
	}
}]
