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

// System.print("Processing " + filename)

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

var page = Meta.compile(File.read(filename)).call()

var extension = ".wren.html"
var theme = "./themes/%(Config.theme)/"

// Include function for usage with themes
var Include = Fn.new{|path|
  var body_ = File.read(theme + path + extension)
  return Meta.compile(body_).call().toString
}

var tpl = Config.template.default
Fiber.new {
  if (page.template.toString.trim().count > 0) {
    tpl = page.template.toString
  }
}.try()

var out = Include.call(tpl)
var outname = Path.replace("content/", "") + ".html"
var outpath = Config.out + "/" + outname

// If *.wren file is on inner dir this would fail
// wren-cli cannot create directories

var error = Fiber.new {
  var rendered = File.create(outpath)
  rendered.writeBytes(out)
}.try()

if (error) {
  System.print(error)
}

