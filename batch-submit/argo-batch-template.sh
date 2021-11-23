for x in ERR2535307 ERR4577441 SRR7769602
do
    cat singlem-dev30-tmpl.yaml | sed "s/\$ACCESSION/$x/" >> ./batch-job-processed.yaml
done
