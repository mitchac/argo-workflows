To submit a batch job to argo run.. 
```
./argo-batch-template.sh
```
..to generate a single file with an argo / k8s workflow template for each accession in the script - batch-job-processed.yaml.
Then run ..
```
argo submit batch-job-processed.yaml -n argo
```
..to submit these workflows to argo. The command output should look as follows..
```
Name:                singlem-mczmm
Namespace:           argo
ServiceAccount:      argo
Status:              Pending
Created:             Tue Nov 23 12:57:11 +1000 (1 second ago)
Progress:            
Parameters:          
  SRA_accession_num: ERR2535307
Name:                singlem-q2fzw
Namespace:           argo
ServiceAccount:      argo
Status:              Pending
Created:             Tue Nov 23 12:57:12 +1000 (now)
Progress:            
Parameters:          
  SRA_accession_num: ERR4577441
Name:                singlem-k4c8z
Namespace:           argo
ServiceAccount:      argo
Status:              Pending
Created:             Tue Nov 23 12:57:13 +1000 (now)
Progress:            
Parameters:          
  SRA_accession_num: SRR7769602
```
This script was adapted from the following link: 
https://kubernetes.io/docs/tasks/job/parallel-processing-expansion/#create-jobs-based-on-a-template
