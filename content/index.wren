
class Page {
  static title {"Welcome to Chercan Static Site Generator"}

  // Include a normal html file
  static content {Content.read()}
}

return Page
