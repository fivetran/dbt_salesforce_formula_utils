{%- macro sfdc_formula_view_fields(join_to_table, source_name = 'salesforce', inclusion_fields=none) -%}

{%- set not_null_value = true -%}
--Generate the key value pair from the view_sql field within the formula table with the below macro.
{%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'view_sql', join_to_table, inclusion_fields, not_null_value) -%}

--Only run the below code if the key_val for view_sql contains data
{% if key_val is not none %}
    {%- for k, v in key_val %}
        view_sql_{{ loop.index }}.{{ k }} ,
    {% endfor -%}
{% endif %}

{%- endmacro -%}