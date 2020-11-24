
class Page {
  static title {"Hello Chercán"}
  static content {Asciidoc.read()}
  static myprop {"This is a special property available just to home.html"}

  // Selecting other value as the base template
  static template {"home"}
}

return Page
