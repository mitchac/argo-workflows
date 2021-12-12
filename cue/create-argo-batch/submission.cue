package create_argo_batch

_cloud_provider: "aws"

//_output_storage_key: _data.summary
_output_storage_key: "tf_test"

// restrict workflows to only run on specific nodes / nodegroups
_node_restrictions: "yes"
