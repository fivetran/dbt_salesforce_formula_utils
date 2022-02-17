{%- macro sfdc_formula_view_fields(join_to_table, source_name = 'salesforce', inclusion_fields=none, not_null_value=true) -%}

--Generate the key value pair from the view_sql field within the formula table with the below macro.
{%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'view_sql', join_to_table, not_null_value) -%}


--Only run the below code if the key_val for view_sql contains data
{% if key_val is not none %}
    -- runs for cases when there are inclusion fields specified
    {% if inclusion_fields is not none %}
        {%- for k, v in key_val if k in inclusion_fields %}
            , view_sql_{{ loop.index }}.{{ k }}
        {% endfor %}

     -- for cases where all formula fields are to be ran   
    {% else %}
        {%- for k, v in key_val %}
            , view_sql_{{ loop.index }}.{{ k }}
        {% endfor -%}
    {% endif %}
{% endif %}

{%- endmacro -%}