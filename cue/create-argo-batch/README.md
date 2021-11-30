### Merge SRA accessions into Argo workflow template and submit to Argo 

Install yq >= 4.15 from.. 

https://github.com/mikefarah/yq

Install cue >= 0.4.0 from.. 

https://github.com/cue-lang/cue

Note that cue files in this directory are all intended to be merged or eval'd together. However, because the cue code is split into different files, each file that you want to 'merge' needs to have the same package annotation at the start of the file. All cue files in this section of the repo belong to the same package - ie "create_argo_batch". In the cue eval command below the -p flag is used to specify which group of files / package we are merging together.  

To keep this directory tidy I've moved all cue files containing data to the "runlists" directory. To merge one of these files just cd into the runlists directory, copy the data file you wish to merge to the parent directory - ie into the directory containing the file workflow_template.cue then cd .. 

Also note that workflow_template.cue expects to merge a "_data" struct not a "data" struct. Underscored structs are hidden from the merge output hence the adoption of this naming convention. 

If you wish to import a new data set in json or yaml format run..

```
cue import my_file.json
```

..to import this into cue format. Then ensure that it conforms to the above requirements if you wish to merge it into the workflow template. 

Then edit vars.cue and set cloud_provider to either "aws" or "gcp" to generate argo templates for your target cloud platform. 

Then run the following command to merge the run list into the workflow template.. 

```
cue eval . --out yaml -p create_argo_batch > merged-workflow-templates-list.yaml
```

..then run the following command to separate each of the generated workflow templates with the yaml separator.. 

```
yq eval '.merged_templates.[] | splitDoc' merged-workflow-templates-list.yaml > merged-workflow-templates-split.yaml
```

..then confirm that you are authenticated to correct k8s cluster and submit the workflow templates to argo..

```
argo submit merged-workflow-templates-split.yaml -n argo
```
