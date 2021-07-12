{%- macro sfdc_formula_view_sql(join_to_table, source_name = 'salesforce') -%}

    --Generate the key value pair from the formula field table with the below macro.
    {%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'view_sql', join_to_table, no_nulls = true) -%}

    {%- set view_sql_ref = [] -%}
    
    --Only run the below code if the key_val for the view sql has data
    {% if key_val is not none %}
        {% for k, v in key_val %}

            --The select statement must explicitly query from and join from the source, not the target. The replace filters point the query to the source.
            {% if ' from ' in v %}
                {%- set v =  v | replace('from','from ' + source(source_name,'fivetran_formula') | string ) -%}
                {%- set v =  v | replace('fivetran_formula','') -%}
            {% endif %}
            
            {% if 'left join' in v %}
                {%- set v =  v | replace('join','join ' + source(source_name,'fivetran_formula') | string ) -%}
                {%- set v =  v | replace('fivetran_formula','') -%}
            {% endif %} --What about if join and from are in the names

            --To ensure the reference is unique across view sql the index of the loop is used in the reference name
            , ( {{ v }} ) as view_sql_{{ loop.index }}

            {{ view_sql_ref.append(loop.index | string )|default("", True) }}
        {% endfor %}
        
        --A where clause is needed to properly leverage the view sql. The below joins the views to the base table using the base ID.
        {%- for lookup in view_sql_ref %} 
            {% if loop.first %}where {% endif %} {{ join_to_table }}.id = view_sql_{{ lookup }}.id
            {% if not loop.last %}  
            and {% endif %}
        {% endfor -%}
    {% endif %}

{%- endmacro -%}