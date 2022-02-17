{%- macro sfdc_formula_view_sql(join_to_table, source_name = 'salesforce', reserved_table_name=join_to_table, inclusion_fields=none, not_null_value=true) -%}

    --Generate the key value pair from the formula field table with the below macro.
    {%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'view_sql', join_to_table, not_null_value) -%}

    {%- set view_sql_ref = [] -%}

    --Only run the below code if the key_val for the view sql has data
    {% if key_val is not none %}
        {% for k, v in key_val if k in inclusion_fields %}

            --The select statement must explicitly query from and join from the source, not the target. The replace filters point the query to the source.
            {% if ' from ' in v %}
                {%- set v = v | replace(' from ',' from ' + source(source_name,'fivetran_formula') | string ) -%}
                {% if target.type == 'bigquery' %} {%- set v = v | replace('`fivetran_formula`','') -%} 
                {% elif target.type == 'redshift' %} {%- set v = v | replace('"fivetran_formula"', '') -%} 
                {% else %} {%- set v = v | replace('fivetran_formula','') -%} {% endif %}
            {% endif %}

            {% if ' left join ' in v %}
                {%- set v = v | replace(' left join ',' left join ' + source(source_name,'fivetran_formula') | string ) -%}
                {% if target.type == 'bigquery' %} {%- set v = v | replace('`fivetran_formula`','') -%} 
                {% elif target.type == 'redshift' %} {%- set v = v | replace('"fivetran_formula"', '') -%} 
                {% else %} {%- set v = v | replace('fivetran_formula','') -%} {% endif %}
            {% endif %}

            --To ensure the reference is unique across view sql the index of the loop is used in the reference name
            , ( {{ v }} ) as view_sql_{{ loop.index }}

            {{ view_sql_ref.append(loop.index | string )|default("", True) }}
        {% endfor %}

        --A where clause is needed to properly leverage the view sql. The below joins the views to the base table using the base ID.
        {%- for lookup in view_sql_ref %}
            {% if loop.first %}where {% endif %} {{ reserved_table_name }}.id = view_sql_{{ lookup }}.id
            {% if not loop.last %}
            and {% endif %}
        {% endfor -%}
    {% endif %}

{%- endmacro -%}
