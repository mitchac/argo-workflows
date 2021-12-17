package create_argo_batch

_accession: {acc: string, acc_lowercase: string, mbases: int, mbytes: int}

_data: {
	summary: =~"^[A-Za-z0-9-_]+$"
	sra_accessions: [..._accession]
}
