
class Page {
  static title {"Hello Chercán"}

  // Include an Asciidoc render html
  static content {Content.adoc()}

  static myprop {"This is a special property available just to themes/default/home.wren.html"}

  // Selecting other value as the base template
  static template {"home"}
}

return Page
