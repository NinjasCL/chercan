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

// Asciidoctor helper
class Asciidoc {
  static read() {
    // Compile hello.adoc using asciidoctor first
    var dir = Path.replace("content/", "")

    var doc = Path + "/" + dir + ".html"
    if (!File.exists(doc)) {
      Fiber.abort(doc + " does not exists")
    }
    var content = File.read(doc)
    var needle = "<body class=\"article\">"
    var start = content.indexOf(needle) + needle.count
    var end = content.indexOf("</body>")
    return content[start...end]
  }
}

// This will be available inside templates
var page = Meta.compile(File.read(filename)).call()

// this is the echo function inside templates
// use it to output content to the final preprocessed template
var echoes_ = []
var echo = Fn.new {|body|
    if (body) {
        echoes_.add(body.toString)
    }
}

// Preprocessor for template files
var tplNeedle = "<?wren"
var tplNeedleEnd = "?>"

var preprocess = Fn.new {|content, index|

    var start = content.indexOf(tplNeedle, index)
    index = start

    var end = content.indexOf(tplNeedleEnd, start)
    var code = content[start + tplNeedle.count...end]

    var result = Meta.compile(code).call(echo)
    var out = echoes_.join("").toString

    // Reset echo item bag
    echoes_ = []

    return [content.replace(tplNeedle + code + tplNeedleEnd, out), index]
}

// include file function
var include = Fn.new {|path|
  var extension_ = ".wren.html"
  var theme_ = "./themes/%(Config.theme)/"
  var body_ = File.read(theme_ + path + extension_)

  // Search for all instances of <?wren tags
  var tagCount = body_.split(tplNeedle).count - 1
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

var tpl = Config.template.default
Fiber.new {
  if (page.template.toString.trim().count > 0) {
    tpl = page.template.toString
  }
}.try()

var out = include.call(tpl)
var outname = Path.replace("content/", "") + ".html"
var outpath = Config.out + "/" + outname

// Output final file
// If *.wren file is on inner dir this would fail
// wren-cli cannot create directories

var rendered = File.create(outpath)
rendered.writeBytes(out)
