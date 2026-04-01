;; extends

(function_declaration
  name: (identifier) @function.definition
  (#set! priority 110))

(function
  name: (identifier) @function.definition
  (#set! priority 110))

(method_definition
  name: (property_identifier) @function.method.definition
  (#set! priority 110))

(class_declaration
  name: (identifier) @type.definition
  (#set! priority 110))

(variable_declarator
  name: (identifier) @function.definition
  value: [(function) (arrow_function)]
  (#set! priority 110))

(assignment_expression
  left: (identifier) @function.definition
  right: [(function) (arrow_function)]
  (#set! priority 110))

(assignment_expression
  left: (member_expression
    property: (property_identifier) @function.method.definition)
  right: [(function) (arrow_function)]
  (#set! priority 110))
