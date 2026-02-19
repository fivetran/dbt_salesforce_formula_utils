{{ salesforce_formula_utils.sfdc_formula_view(
    source_table = 'account',
    using_quoted_identifiers = var('using_quoted_identifiers', false),
    full_statement_version=true) }} --leaving full_statement_version=true in this model to make sure it doesn't error