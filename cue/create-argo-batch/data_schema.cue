package create_argo_batch

_accession: {acc: string, mbases: int, mbytes: int}

_data: {
	summary: =~"^[A-Za-z0-9-]+$"
	sra_accessions: [..._accession]
}
