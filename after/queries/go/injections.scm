; extends

(call_expression
  (selector_expression
    field: (field_identifier) @_field
    (#match? @_field "^(Query|QueryContext|Exec|ExecContext|Prepare|PrepareContext)$"))
  (argument_list
    (raw_string_literal) @sql))
