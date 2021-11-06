for x in ERR2535307 ERR4577441 SRR7769602
do
    argo submit -n argo --from=wftmpl/kingfisher-gdnml -p SRA_accession_num=$x
done
