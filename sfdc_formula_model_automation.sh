#!/bin/bash
mkdir -p $1/models
echo "" >> $1/models/$2_view.sql
echo "{{ salesforce_formula_utils.sfdc_formula_view('$2') }}" >> $1/models/$2_view.sql