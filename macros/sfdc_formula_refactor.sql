{%- macro sfdc_formula_refactor(join_to_table, source_name) -%}

    --Generate the key value pair from the formula field table with the below macro.
    {%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'sql', join_to_table) -%}

    --Creating a permanent array to be carried over after this macro.
    {%- set adjusted_key_val = [] -%}

    {%- for key, value in key_val %}
        
        {%- set temp_array = [] -%} --Creating a temporary array for the key (field name) and value (sql) pairs to be created within.
        {{ temp_array.append(key)|default("", True)  }} --The key will always be appended without additional adjustments.

        --If the field name is found within the sql of another field. Then an adjustment to the sql will take place
        --The adjustment will replace the field name with the true sql of the other formual field.
        {%- for field, sql in key_val -%}
            {%- if field in value -%}
                {%- if sql == 'null_value' -%}
                    {{ temp_array.append( value | replace(field,"(null)") )| default("", True) }}
                {% else %}
                    {{ temp_array.append( value | replace(field,"(" ~ sql ~ ")") )| default("", True) }}
                {% endif %}
            {%- endif -%}
        {%- endfor -%}

        --If a the temp array length only contains one value, then that means there was no adjustment need.
        --As such, the original sql value will be appened to the temporary array
        {% if temp_array | length < 2 %}
            {{ temp_array.append( value )| default("", True) }}
        {% endif %}

        --The key (formula field name) and value (sql) within the temporary array are appended to a permanent adjusted_key_val array.
        --This array is then used within the final sfdc_formula_view macro.
        {{ adjusted_key_val.append(temp_array | list)|default("", True) }}
    {% endfor -%}

    --Create a new variable and set the value to the list generated from adjusted_key_val.
    --Return this variable to be used in the next macro
    {%- set adjusted_values = adjusted_key_val | list %}
    {{ return(adjusted_values) }}

{%- endmacro -%}