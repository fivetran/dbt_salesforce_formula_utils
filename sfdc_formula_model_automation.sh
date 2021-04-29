#!/bin/bash
mkdir -p $1/models
echo "" >> $1/models/$3_view.sql
echo "
{{ salesforce_formula_utils.sfdc_formula_view('$3') }}" >> $1/models/$3_view.sql