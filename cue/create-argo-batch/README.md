### Merge SRA accessions into Argo workflow template and submit to Argo 

Install yq >= 4.15 from.. 

https://github.com/mikefarah/yq

Install cue >= 0.4.0 from.. 

https://github.com/cue-lang/cue

Then run the following command to merge the run list into the workflow template.. 

```
cue eval ./... --out yaml > merged-workflow-templates-list.yaml
```

Then run the following command to separate each of the workflow templates with the yaml separator.. 

```
yq eval '.merged_templates.[] | splitDoc' merged-workflow-templates-list.yaml > merged-workflow-templates-split.yaml
```

Submit the workflow templates to argo..

```
argo submit merged-workflow-templates-split.yaml -n argo
```
