;; extends

(function_definition
  name: (identifier) @function.definition
  (#set! priority 110))

(class_definition
  name: (identifier) @type.definition
  (#set! priority 110))

(decorator
  (identifier) @attribute
  (#set! priority 110))

(decorator
  (attribute
    attribute: (identifier) @attribute)
  (#set! priority 110))
