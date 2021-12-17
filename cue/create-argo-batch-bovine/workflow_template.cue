package create_argo_batch

// import "list"

merged_templates: [ for acc in _data.sra_accessions {
	{
		apiVersion: "argoproj.io/v1alpha1"
		kind:       "Workflow"
		metadata: {
			generateName: "bovine-" + acc["acc_lowercase"] + "-"
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
					resources: requests: storage: "5000Mi" // while testing just use 5
				}
			}]
			entrypoint: "bovine-task"
			ttlStrategy: {
				secondsAfterCompletion: 300  // Time to live after workflow is completed, replaces ttlSecondsAfterFinished
				secondsAfterSuccess:    300  // Time to live after workflow is successful
				secondsAfterFailure:    3600 // 3 hours
			} // Time to live after workflow fails
			arguments: {
				parameters: [{
					name:  "SRA_accession_num"
					value: acc["acc"]
				},{
					name:  "studyID"
					value: acc["studyID"]
				},{
					name:  "R1"
					value: acc["R1"]
				},{
					name:  "R2"
					value: acc["R2"]
				}
				]
			}
			templates: [{
				name: "bovine-task"
				retryStrategy: {
					limit:       "3"
					retryPolicy: "OnError"
				}
				inputs: {
					parameters: [{
						name:  "SRA_accession_num"
						value: acc["acc"]
					},{
						name:  "studyID"
						value: acc["studyID"]
					},{
						name:  "R1"
						value: acc["R1"]
					},{
						name:  "R2"
						value: acc["R2"]
					}
					]
				}
				archiveLocation: {
					archiveLogs: true
					if _cloud_provider == "aws" {
						s3: {
							endpoint: _cloud_configs.aws.storage.endpoint
							bucket:   _cloud_configs.aws.storage.bucket
							key:      "\(_output_storage_key)/results/{{workflow.parameters.studyID}}.metaspades-{{workflow.name}}"
						}
					}
					// if _cloud_provider == "gcp" {
					// 	gcs: {
					// 		bucket: _cloud_configs.gcp.storage.bucket
					// 		key:    "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}"
					// 	}
					// }
				}
				container: {
					name:  "bovine"
					image: "public.ecr.aws/m5a0r7u5/spades:v2"
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
echo Copying R1 s3://cmr-bovine-assembly/{{workflow.parameters.R1}} ..;
aws s3 cp s3://cmr-bovine-assembly/{{workflow.parameters.R1}} .;
echo Copying R2 s3://cmr-bovine-assembly/{{workflow.parameters.R2}} ..;
aws s3 cp s3://cmr-bovine-assembly/{{workflow.parameters.R2}} .;
ls -lh;
metaspades.py -k 21,33,55,77,99 -m 488 -1 {{workflow.parameters.R1}} -2 {{workflow.parameters.R2}} -t 64 -o {{workflow.parameters.studyID}}.metaspades
""",
					]

					volumeMounts: [{
						name:      "workdir"
						mountPath: "/mnt/vol"
					}]
					resources: {
						limits: { // FIXME
							cpu: "400m"
							memory: "3584Mi"
						}
						requests: { // FIXME
							memory:                    "512Mi" 
							cpu:                       "400m"
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
						path: "/mnt/vol/{{workflow.parameters.studyID}}.metaspades"
						// archive:
						// 	none: {} // Do not apply the argo default tar.gz since we are already gzipped and it is only 1 file
						if _cloud_provider == "aws" {
							s3: {
								endpoint: _cloud_configs.aws.storage.endpoint
								bucket:   _cloud_configs.aws.storage.bucket
								key:      "\(_output_storage_key)/results/{{workflow.parameters.studyID}}.metaspades-{{workflow.name}}"
							}
						}
						// if _cloud_provider == "gcp" {
						// 	gcs: {
						// 		bucket: _cloud_configs.gcp.storage.bucket
						// 		key:    "\(_output_storage_key)/{{workflow.name}}-{{workflow.parameters.SRA_accession_num}}/{{workflow.parameters.SRA_accession_num}}.annotated.singlem.json.gz"
						// 	}
						// }
					}
				]
			}]
	}
	}
}]
