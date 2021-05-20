{% macro sfdc_get_formula_column_values(fivetran_formula, key, value, join_to_table) -%}

{#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. #}
    {%- if not execute -%}
        {{ return('') }}
    {% endif %}
{#--  #}

    -- Operation to query from the source.
    {%- set target_relation = adapter.get_relation(database=fivetran_formula.database,
        schema=fivetran_formula.schema,
        identifier=fivetran_formula.identifier) -%}

    {%- call statement('get_column_values', fetch_result=true) %}

        {%- if not target_relation -%}
            -- exception raised if the source table defined does not exist
            {{ exceptions.raise_compiler_error("In get_column_values(): relation " ~ fivetran_formula ~ " does not exist and no default value was provided.") }}

        {%- else -%}
            -- Query used to obtain the unique groupings for key (field) and value (sql) from the formula_field table
            select
                {{ key }} as key,
                case when {{ value }} is null
                    then 'null_value'               -- Since none type values cannot be iterated over in a dataframe, this is set to string 'null_value' and is changed later back to null.
                    else {{ value }}
                        end as value
            from {{ target_relation }}
            where object = '{{ join_to_table }}'    -- This filters the query to only include the formula fields referenced by the source table.
                and {{ key }} not in {{ var('sfdc_exclude_formulas',"('')") }} -- Excludes any formula fields the user may have set within the sfdc_exclude_formulas variable. Default is an empty string.
            group by 1, 2
            order by count(*) desc

        {% endif %}
    {%- endcall -%}

    -- Creates a new variable and sets the contents to the result of the above query.
    {%- set value_list = load_result('get_column_values') -%}

    -- Create another variable and loads the data contents as a list. This variable is then returned when the macro is called.
    {%- set values = value_list['data'] | list %}
    {{ return(values) }}

{%- endmacro %}