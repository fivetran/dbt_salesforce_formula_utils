{%- macro sfdc_formula_refactor(join_to_table, source_name = 'salesforce') -%}

    --Generate the key value pair from the formula field table with the below macro.
    {%- set key_val = salesforce_formula_utils.sfdc_get_formula_column_values(source(source_name, 'fivetran_formula'), 'field', 'sql', join_to_table) -%}

    --Creating a permanent array to be carried over after this macro.
    {%- set adjusted_key_val = [] -%}

    {%- for key, value in key_val %}
        
        {%- set temp_array = [] -%} --Creating a temporary array for the key (field name) and value (sql) pairs to be created within.
        {{ temp_array.append(key)|default("", True)  }} --The key will always be appended without additional adjustments.
        {{ temp_array.append(" " ~ value ~ " ")|default("", True)  }} --The value will start off as being the original sql value with spaces on both ends to allow for string searching.

        {%- for field, sql in key_val -%}
            --If the last item in the list contains the another field then insert that sql into the sql and append a new item onto the list.
            {%- if " " ~ field ~ " " in temp_array[-1] -%}
                {{ temp_array.append( temp_array[-1] | replace(field,"(" ~ sql ~ ")") )| default("", True) }}
            {% endif %}

            --If a sql field contains the string'null_value' then replace it with a true null
            {%- if 'null_value' in temp_array[-1] -%}
                    {{ temp_array.append( temp_array[-1] | replace('null_value','null') )| default("", True) }}
            {% endif %}

            --One last for loop to perform recursive searching on all fields to allow for more dynamic referential formula capture
            {% for k,v in key_val %}
                {% if " " ~ k ~ " " in temp_array[-1] %} 
                    {{ temp_array.append( temp_array[-1] | replace(k,"( " ~ v ~ " )") )| default("", True) }}
                {% endif %}
            {% endfor %}
        {%- endfor -%}

        --The key (formula field name) and latest value (sql) within the temporary array are appended to a permanent adjusted_key_val array.
        --This array is then used within the final sfdc_formula_view macro.
        {{ adjusted_key_val.append((temp_array[0],temp_array[-1]) ) }}
    {% endfor -%}

    --Create a new variable and set the value to the list generated from adjusted_key_val.
    --Return this variable to be used in the next macro
    {%- set adjusted_values = adjusted_key_val | list %}
    {{ return(adjusted_values) }}

{%- endmacro -%}