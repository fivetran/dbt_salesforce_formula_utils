{%- macro sfdc_formula_pivot(join_to_table, source_name='salesforce') -%}

    {%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'sql', join_to_table) -%}

    {% for k, v in key_val %}
        {% if v == 'null_value' %}
            null as {{ k }}
        {% else %}
            {{ v }} as {{ k }}
        {% endif %}
        {%- if not loop.last -%},{%- endif -%}
    {% endfor %}

{%- endmacro -%}