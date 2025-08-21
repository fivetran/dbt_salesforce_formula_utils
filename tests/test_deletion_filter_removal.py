#!/usr/bin/env python3
"""
Test script to verify the regex patterns in the sfdc_formula_view macro
work correctly for removing deletion filtering logic.
"""

import re

def test_deletion_filter_removal():
    """Test various deletion filtering patterns that should be removed."""
    
    test_cases = [
        # Basic WHERE clause patterns
        {
            'input': 'SELECT * FROM table WHERE NOT main._fivetran_deleted',
            'expected': 'SELECT * FROM table',
            'description': 'Simple WHERE NOT _fivetran_deleted'
        },
        {
            'input': 'SELECT * FROM table WHERE main._fivetran_deleted = false',
            'expected': 'SELECT * FROM table',
            'description': 'WHERE _fivetran_deleted = false'
        },
        {
            'input': 'SELECT * FROM table WHERE NOT main._fivetran_deleted AND other_condition = true',
            'expected': 'SELECT * FROM table WHERE other_condition = true',
            'description': 'WHERE NOT _fivetran_deleted AND other_condition'
        },
        {
            'input': 'SELECT * FROM table WHERE other_condition = true AND NOT main._fivetran_deleted',
            'expected': 'SELECT * FROM table WHERE other_condition = true',
            'description': 'WHERE other_condition AND NOT _fivetran_deleted'
        },
        {
            'input': 'SELECT * FROM table WHERE cond1 = true AND NOT main._fivetran_deleted AND cond2 = false',
            'expected': 'SELECT * FROM table WHERE cond1 = true AND cond2 = false',
            'description': 'WHERE condition AND NOT _fivetran_deleted AND condition'
        },
        
        # History table patterns
        {
            'input': 'SELECT * FROM table WHERE main._fivetran_active',
            'expected': 'SELECT * FROM table',
            'description': 'WHERE _fivetran_active (history table)'
        },
        {
            'input': 'SELECT * FROM table WHERE main._fivetran_active = true AND other_condition = 1',
            'expected': 'SELECT * FROM table WHERE other_condition = 1',
            'description': 'WHERE _fivetran_active = true AND other_condition'
        },
        
        # JOIN condition patterns
        {
            'input': 'SELECT * FROM table1 t1 LEFT JOIN table2 t2 ON t1.id = t2.parent_id AND NOT t2._fivetran_deleted',
            'expected': 'SELECT * FROM table1 t1 LEFT JOIN table2 t2 ON t1.id = t2.parent_id',
            'description': 'JOIN with AND NOT _fivetran_deleted'
        },
        
        # Quoted identifier patterns
        {
            'input': 'SELECT * FROM table WHERE NOT main.`_fivetran_deleted`',
            'expected': 'SELECT * FROM table',
            'description': 'Backtick quoted identifiers'
        },
        {
            'input': 'SELECT * FROM table WHERE NOT main."_fivetran_deleted"',
            'expected': 'SELECT * FROM table',
            'description': 'Double quoted identifiers'
        },
        
        # Complex patterns
        {
            'input': 'SELECT * FROM table WHERE (NOT main._fivetran_deleted) AND other_condition = true',
            'expected': 'SELECT * FROM table WHERE other_condition = true',
            'description': 'Parenthetical deletion condition'
        },
    ]
    
    # Regex patterns from the macro (simplified for testing)
    patterns = [
        # WHERE NOT table._fivetran_deleted AND other_condition -> WHERE other_condition
        (r'WHERE\s+NOT\s+\w+\._fivetran_deleted\s+AND\s+', 'WHERE '),
        
        # WHERE other_condition AND NOT table._fivetran_deleted -> WHERE other_condition
        (r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted(?=\s|$)', r'\1'),
        
        # WHERE condition1 AND NOT table._fivetran_deleted AND condition2 -> WHERE condition1 AND condition2
        (r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted\s+AND\s+', r'\1 AND '),
        
        # WHERE _fivetran_deleted = false AND other_condition -> WHERE other_condition
        (r'WHERE\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s+AND\s+', 'WHERE '),
        (r'(\bWHERE\s+.+?)\s+AND\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))(?=\s|$)', r'\1'),
        
        # Simple cases: WHERE only _fivetran_deleted
        (r'WHERE\s+NOT\s+\w+\._fivetran_deleted\s*$', ''),
        (r'WHERE\s+\w+\._fivetran_deleted\s*(?:=\s*(?:false|0)|!=\s*(?:true|1))\s*$', ''),
        
        # History table patterns
        (r'WHERE\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s+AND\s+', 'WHERE '),
        (r'(\bWHERE\s+.+?)\s+AND\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?(?=\s|$)', r'\1'),
        (r'WHERE\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?\s*$', ''),
        
        # JOIN conditions
        (r'(\bON\s+.+?)\s+AND\s+NOT\s+\w+\._fivetran_deleted(?=\s|$|\n)', r'\1'),
        (r'(\bON\s+.+?)\s+AND\s+\w+\._fivetran_active(?:\s*=\s*(?:true|1))?(?=\s|$|\n)', r'\1'),
        
        # Quoted identifiers - backticks
        (r'WHERE\s+NOT\s+\w+\.`_fivetran_deleted`\s+AND\s+', 'WHERE '),
        (r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\.`_fivetran_deleted`(?=\s|$)', r'\1'),
        (r'WHERE\s+NOT\s+\w+\.`_fivetran_deleted`\s*$', ''),
        
        # Quoted identifiers - double quotes
        (r'WHERE\s+NOT\s+\w+\."_fivetran_deleted"\s+AND\s+', 'WHERE '),
        (r'(\bWHERE\s+.+?)\s+AND\s+NOT\s+\w+\."_fivetran_deleted"(?=\s|$)', r'\1'),
        (r'WHERE\s+NOT\s+\w+\."_fivetran_deleted"\s*$', ''),
        
        # Parenthetical conditions
        (r'\(\s*NOT\s+\w+\._fivetran_deleted\s*\)\s*AND\s+', ''),
        (r'\s+AND\s+\(\s*NOT\s+\w+\._fivetran_deleted\s*\)', ''),
        
        # Cleanup
        (r'WHERE\s*$', ''),
        (r'WHERE\s+AND\s+', 'WHERE '),
        (r'\s{2,}', ' '),
    ]
    
    def apply_patterns(sql):
        """Apply all regex patterns to clean the SQL."""
        for pattern, replacement in patterns:
            sql = re.sub(pattern, replacement, sql, flags=re.IGNORECASE)
        return sql.strip()
    
    # Run tests
    passed = 0
    failed = 0
    
    for test_case in test_cases:
        input_sql = test_case['input']
        expected = test_case['expected']
        description = test_case['description']
        
        result = apply_patterns(input_sql)
        
        if result == expected:
            print(f"✓ PASS: {description}")
            passed += 1
        else:
            print(f"✗ FAIL: {description}")
            print(f"  Input:    {input_sql}")
            print(f"  Expected: {expected}")
            print(f"  Got:      {result}")
            failed += 1
    
    print(f"\nResults: {passed} passed, {failed} failed")
    return failed == 0

if __name__ == '__main__':
    success = test_deletion_filter_removal()
    exit(0 if success else 1)