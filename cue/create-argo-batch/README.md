### Merge SRA accessions into Argo workflow template and submit to Argo 

Install yq >= 4.15 from.. 

https://github.com/mikefarah/yq

Install cue >= 0.4.0 from.. 

https://github.com/cue-lang/cue

Note that cue files in this directory are all intended to be merged or eval'd together. However, because the cue code is split into different files, each file that you want to 'merge' needs to have the same package annotation at the start of the file. All cue files in this section of the repo belong to the same package - ie "create_argo_batch". In the cue eval command below the -p flag is used to specify which group of files / package we are merging together.  

To keep this directory tidy I've moved all cue files containing data to the "runlists" directory. 

Also note that workflow_template.cue expects to merge a "_data" struct not a "data" struct. Underscored structs are hidden from the merge output hence the adoption of this naming convention. The first line of the runlist file must be `package create_argo_batch` also.

If you wish to import a new data set in json or yaml format run..

```
cue import -o - my.json |sed 's/^data/package create_argo_batch\n\n_data/'
```

..to import this into cue format. The sed modifies the default output to conform to the above two extra requirements so it can be merged with the workflow template. 

Then edit submission.cue and set cloud_provider to either "aws" or "gcp" to generate argo templates for your target cloud platform. 

Then replace <MY-DATA-FILE.cue> in the following command with the name of your data file in cue format. 

Then run the following command to merge the run list into the workflow template and submit to argo.

```
cue eval . ./runlists/<MY-DATA-FILE.cue> --out yaml -p create_argo_batch |yq eval '.merged_templates.[] | splitDoc' - >merged-workflow-templates-list.yaml
```
Then submit, keeping a log of the IDs
```
argo submit - -n argo -o json merged-workflow-templates-list.yaml |jq > submissions/`date +%Y%m%d-%k%M`.argo_submission.json
```
