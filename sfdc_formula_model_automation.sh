#!/bin/bash
setopt shwordsplit
variable=($2)
for i in ${variable//,/ }
    do
    # call your procedure/other scripts here below
    mkdir -p $1/models
    echo "" >> $1/models/"$i".sql
    echo "{{ salesforce_formula_utils.sfdc_formula_view('$i') }}" >> $1/models/"$i".sql
done