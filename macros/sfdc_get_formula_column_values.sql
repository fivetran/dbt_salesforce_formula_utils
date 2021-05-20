{% macro sfdc_get_formula_column_values(fivetran_formula, key, value, join_to_table, max_records=none, default=none) -%}

{#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. #}
    {%- if not execute -%}
        {{ return('') }}
    {% endif %}
{#--  #}

    {%- set target_relation = adapter.get_relation(database=fivetran_formula.database,
        schema=fivetran_formula.schema,
        identifier=fivetran_formula.identifier) -%}

    {%- call statement('get_column_values', fetch_result=true) %}

        {%- if not target_relation and default is none -%}

            {{ exceptions.raise_compiler_error("In get_column_values(): relation " ~ fivetran_formula ~ " does not exist and no default value was provided.") }}

        {%- elif not target_relation and default is not none -%}

            {{ log("Relation " ~ fivetran_formula ~ " does not exist. Returning the default value: " ~ default) }}

            {{ return(default) }}

        {%- else -%}

            select
                {{ key }} as key,
                case when {{ value }} is null
                    then 'null_value'
                    else {{ value }}
                        end as value

            from {{ target_relation }}
            where object = '{{ join_to_table }}'
                and {{ key }} not in {{ var('sfdc_exclude_formulas',"('')") }}
            group by 1, 2
            order by count(*) desc

            {% if max_records is not none %}
            limit {{ max_records }}
            {% endif %}

        {% endif %}

    {%- endcall -%}

    {%- set value_list = load_result('get_column_values') -%}

    {%- if value_list and value_list['data'] -%}
        {%- set values = value_list['data'] | list %}
        {{ return(values) }}
    {%- else -%}
        {{ return(default) }}
    {%- endif -%}

{%- endmacro %}