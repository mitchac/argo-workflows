package create_argo_batch

_cloud_provider: "aws"

_output_storage_key: _data.summary

// restrict workflows to only run on specific nodes / nodegroups
_node_restrictions: "yes"
