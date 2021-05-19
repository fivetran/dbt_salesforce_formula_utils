{%- macro sfdc_formula_pivot(join_to_table) -%}

    {%- set key_val = salesforce_formula_utils.sfdc_formula_refactor(join_to_table) -%}

    {% for k, v in key_val %}
        {% if v == 'null_value' %}
            null as {{ k }}
        {% else %}
            {{ v }} as {{ k }}
        {% endif %}
        {%- if not loop.last -%},{%- endif -%}
    {% endfor %}

{%- endmacro -%}