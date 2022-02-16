{%- macro sfdc_formula_pivot(join_to_table, source_name='salesforce', added_inclusion_fields=none) -%}

    -- The results generated from sfdc_formula_refactor are set to the key_val variable.
    {%- set key_val = salesforce_formula_utils.sfdc_formula_refactor(join_to_table, source_name, added_inclusion_fields) -%}

    -- k being the field name and v being the sql.
    {% for k, v in key_val if k in added_inclusion_fields and k is not none %}
        , {%- if v == 'null_value' %}
            null as {{ k }} -- Switching the string null to a true null as we will no longer need to iterate through a nonetype.
        {% else -%}
            {{ v }} as {{ k }}
        {% endif -%}
    {% endfor %}

{%- endmacro -%}