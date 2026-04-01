;; extends

(method_declaration
  name: (identifier) @function.method.definition
  (#set! priority 110))

(constructor_declaration
  name: (identifier) @constructor.definition
  (#set! priority 110))

(class_declaration
  name: (identifier) @type.definition
  (#set! priority 110))

(interface_declaration
  name: (identifier) @type.definition
  (#set! priority 110))

(enum_declaration
  name: (identifier) @type.definition
  (#set! priority 110))

(annotation
  name: (identifier) @attribute
  (#set! priority 110))

(marker_annotation
  name: (identifier) @attribute
  (#set! priority 110))

(normal_annotation
  name: (identifier) @attribute
  (#set! priority 110))
