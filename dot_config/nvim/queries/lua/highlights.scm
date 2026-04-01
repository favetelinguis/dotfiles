;; extends

(function_declaration
  name: [
    (identifier) @function.definition
    (dot_index_expression
      field: (identifier) @function.definition)
  ]
  (#set! priority 110))

(function_declaration
  name: (method_index_expression
    method: (identifier) @function.method.definition)
  (#set! priority 110))

(assignment_statement
  (variable_list
    .
    name: [
      (identifier) @function.definition
      (dot_index_expression
        field: (identifier) @function.definition)
    ])
  (expression_list
    .
    value: (function_definition))
  (#set! priority 110))

(table_constructor
  (field
    name: (identifier) @function.definition
    value: (function_definition))
  (#set! priority 110))
