;; extends

(function_declaration
  name: (identifier) @function.definition
  (#set! priority 110))

(method_declaration
  name: (field_identifier) @function.method.definition
  (#set! priority 110))

(method_spec
  name: (field_identifier) @function.method.definition
  (#set! priority 110))

(type_spec
  name: (type_identifier) @type.definition
  (#set! priority 110))
