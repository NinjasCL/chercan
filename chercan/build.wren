#!/usr/bin/env wren

import "os" for Process
import "io" for File
import "meta" for Meta

import "./config" for Config

if (!Process.arguments[0]) {
  Fiber.abort("Need filepath. None given.")
}

var Path = Process.arguments[0].toString
var filename = Path + ".wren"

if (!File.exists(filename)) {
  Fiber.abort("File %(filename) does not exists")
}

// this is the echo function inside templates
// use it to output content to the final preprocessed template
var echoes_ = []
var echo = Fn.new {|body|
    if (body) {
        echoes_.add(body.toString)
    }
}

// Preprocessor for template files
var TplNeedle = "<?wren"
var TplNeedleEnd = "?>"

var preprocess = Fn.new {|content, index|

    var start = content.indexOf(TplNeedle, index)
    index = start

    var end = content.indexOf(TplNeedleEnd, start)
    var code = content[start + TplNeedle.count...end]

    var result = Meta.compile(code).call(echo)
    var out = echoes_.join("").toString

    // Reset echo item bag
    echoes_ = []

    return [content.replace(TplNeedle + code + TplNeedleEnd, out), index]
}

var Preprocess = preprocess

// include file function
var include_ = Fn.new {|path, useTheme|
  var extension_ = ".wren.html"
  var theme_ = ""
  if (useTheme) {
    theme_ = "./themes/%(Config.theme)/"
  }
  var body_ = File.read(theme_ + path + extension_)

  // Search for all instances of <?wren tags
  var tagCount = body_.split(TplNeedle).count - 1
  var processed = 0
  var index = 0
  var result = null

  while (processed < tagCount) {
      result = preprocess.call(body_, index)
      body_ = result[0].trimStart()
      index = result[1]
      processed = processed + 1
      echoes_ = []
  }
  return body_
}

// Include a file inside themes
var include = Fn.new{|path| include_.call(path, true)}

// Require a file inside the content/directory path
var require = Fn.new{|name| include_.call(Path + "/" + name, false)}

// Content Helpers
class Content {
  static read(file) {
    // Read
    var doc = Path + "/" + file
    if (!File.exists(doc)) {
      Fiber.abort(doc + " does not exists")
    }
    var content = File.read(doc)
    return content
  }

  static read() {
    var dir = Path.replace("content/", "")
    return Content.read(dir + ".html")
  }

  static render(file) {
    var doc = Path + "/" + file
    if (!File.exists(doc)) {
      Fiber.abort(doc + " does not exists")
    }
    var content = File.read(doc)
    // Search for all instances of <?wren tags
    var tagCount = content.split(TplNeedle).count - 1
    var processed = 0
    var index = 0
    var result = null

    while (processed < tagCount) {
        result = Preprocess.call(content, index)
        content = result[0].trimStart()
        index = result[1]
        processed = processed + 1
    }
    return content
  }

  static render() {
    var dir = Path.replace("content/", "")
    return Content.render(dir + ".wren.html")
  }

  static adoc(file) {
    var content = Content.read(file)
    var needle = "<body class=\"article\">"
    var start = content.indexOf(needle) + needle.count
    var end = content.indexOf("</body>")
    return content[start...end]
  }

  static adoc() {
    var dir = Path.replace("content/", "")
    return Content.adoc(dir + ".html")
  }
}

class Asciidoc {
  static read() {
    return Content.adoc()
  }

  static read(file) {
    return Content.adoc(file)
  }
}

// This will be available inside templates
var page = Meta.compile(File.read(filename)).call()

var tpl = Config.template.default
Fiber.new {
  if (page.template.toString.trim().count > 0) {
    tpl = page.template.toString
  }
}.try()

// Output final file
// If *.wren file is on inner dir this would fail
// wren-cli cannot create directories

var out = include.call(tpl, true)
var outname = Path.replace("content/", "") + ".html"
var outpath = Config.out + "/" + outname

var rendered = File.create(outpath)
rendered.writeBytes(out)
