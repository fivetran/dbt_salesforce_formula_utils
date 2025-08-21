{%- macro sfdc_formula_view(source_table, source_name='salesforce', materialization='view', using_quoted_identifiers=False, full_statement_version=true, reserved_table_name=none, fields_to_include=none, include_deleted_records=true) -%}

-- Best practice for this model is to be materialized as view. That is why we have set that here.
{{
    config(
        materialized = materialization
    )
}}

-- Raise a warning if users are trying to use full_statement_version=false. We are keeping the variable in the macro, however, since we don't want errors if they previously set it to true.
{% if not full_statement_version %}
    {{ exceptions.warn("\nERROR: The full_statement_version=false, reserved_table_name, and fields_to_include parameters are no longer supported. Please update your " ~ this.identifier|upper ~ " model to remove these parameters.\n") }}
    See_full_model_error_in_log

{% else %}

    {% if using_quoted_identifiers %}
    {%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), 
                                                        column='"MODEL"' if target.type in ('snowflake') else '"model"' if target.type in ('postgres', 'redshift', 'snowflake') else '`model`', 
                                                        where=("\"OBJECT\" = '" if target.type in ('snowflake') else "\"object\" = '" if target.type in ('postgres', 'redshift') else "`object` = '") ~ source_table ~ "'") -%}

    {% else %}
    {%- set table_results = dbt_utils.get_column_values(table=source(source_name, 'fivetran_formula_model'), column='model', where="object = '" ~ source_table ~ "'") -%}

    {% endif %}

    {%- set original_sql = table_results[0] -%}
    
    {% if include_deleted_records %}
        {%- set cleaned_sql = original_sql -%}
        
        {# === DELETION FILTERING REMOVAL === #}
        {# Remove all forms of _fivetran_deleted filtering from WHERE clauses #}
        
        {# 1. Handle compound patterns first: WHERE NOT table._fivetran_deleted AND other_condition -> WHERE other_condition #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\._fivetran_deleted\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# 2. WHERE other_condition AND NOT table._fivetran_deleted -> WHERE other_condition #}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted(?=\s|$)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# 3. WHERE condition1 AND NOT table._fivetran_deleted AND condition2 -> WHERE condition1 AND condition2 #}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted\s+AND\s+', '\\1 AND ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# 4. Handle equals/not equals patterns for _fivetran_deleted #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))(?=\s|$)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# 5. Handle simple cases: WHERE only _fivetran_deleted conditions #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\._fivetran_deleted\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# === HISTORY TABLE FILTERING REMOVAL === #}
        {# Remove all forms of _fivetran_active filtering for history tables #}
        
        {# 6. Remove _fivetran_active = true patterns #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?(?=\s|$)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# === JOIN CONDITION FILTERING REMOVAL === #}
        {# Remove deletion filtering from JOIN conditions #}
        
        {# 7. Remove AND NOT table._fivetran_deleted from JOIN conditions #}
        {%- set cleaned_sql = modules.re.sub(r'(\bON\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted(?=\s|$|\n)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'(\bON\s+.+?)\s+AND\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))(?=\s|$|\n)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# 8. Remove AND table._fivetran_active from JOIN conditions #}
        {%- set cleaned_sql = modules.re.sub(r'(\bON\s+.+?)\s+AND\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?(?=\s|$|\n)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# === QUOTED IDENTIFIER HANDLING === #}
        {# Handle all above patterns with backticks (`) #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\.`_fivetran_deleted`\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\.`_fivetran_deleted`(?=\s|$)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\.`_fivetran_deleted`\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\.`_fivetran_deleted`\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\.`_fivetran_active`(?:\s*=\s*(?:true|1))?\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# Handle all above patterns with double quotes (") #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\."_fivetran_deleted"\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\."_fivetran_deleted"(?=\s|$)', '\\1', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\."_fivetran_deleted"\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+NOT\s+\w+\."_fivetran_deleted"\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+\w+\."_fivetran_active"(?:\s*=\s*(?:true|1))?\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# === PARENTHETICAL CONDITIONS === #}
        {# Remove parenthetical deletion conditions like (NOT table._fivetran_deleted) #}
        {%- set cleaned_sql = modules.re.sub(r'\(\s*NOT\s+\w+\._fivetran_deleted\s*\)\s*AND\s+', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'\s+AND\s+\(\s*NOT\s+\w+\._fivetran_deleted\s*\)', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'\(\s*\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s*\)\s*AND\s+', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'\s+AND\s+\(\s*\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s*\)', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# === CLEANUP === #}
        {# Fix any leftover WHERE clauses with no conditions #}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s*$', '', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+AND\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        {%- set cleaned_sql = modules.re.sub(r'WHERE\s+OR\s+', 'WHERE ', cleaned_sql, flags=modules.re.IGNORECASE) -%}
        
        {# Clean up multiple consecutive spaces and normalize whitespace #}
        {%- set cleaned_sql = modules.re.sub(r'\s{2,}', ' ', cleaned_sql) -%}
        {%- set cleaned_sql = modules.re.sub(r'\s+\n', '\n', cleaned_sql) -%}
        {%- set cleaned_sql = modules.re.sub(r'\n\s+', '\n', cleaned_sql) -%}

        {{ cleaned_sql.strip() }}
    
    {% else %}
        {# If include_deleted_records=false, return original SQL with deletion filtering intact #}
        {{ original_sql }}
    
    {% endif %}
{% endif %}
{%- endmacro -%}