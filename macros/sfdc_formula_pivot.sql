{%- macro sfdc_formula_pivot(join_to_table) -%}
    {%- set key_val = sfdc_fivetran_formula.sfdc_get_formula_column_values(source('salesforce', 'fivetran_formula'), 'field', 'sql', join_to_table) -%}

    {% for k, v in key_val %}
        {% if v == 'null_value' %}
            null as {{ k }}
        {% else %}
            {{ v }} as {{ k }}
        {% endif %}
        {%- if not loop.last -%},{%- endif -%}
    {% endfor %}

{%- endmacro -%}