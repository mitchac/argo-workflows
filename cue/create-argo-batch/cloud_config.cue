package create_argo_batch

#cloud_config: {
	storage:
	{
		endpoint?: string
		bucket: string
		key: string
	}
}

_cloud_configs: {
	aws: #cloud_config & {
		storage: {
			endpoint: "s3.amazonaws.com"
			bucket: "batch-artifact-repository-401305384268"
			key:   "test6"
		}
	}
	gcp: #cloud_config & {
		storage: {
			bucket: "bowerbird-testing-home"
			key:   "bowerbird"
		}
	}

}
