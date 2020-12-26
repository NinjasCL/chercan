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

// Preprocessor for Wren tag files
var TagNeedle = "<?wren"
var TagNeedleEchoWrapper = "<?="
var TagNeedleEnd = "?>"
var TagExtension = "wren.html"
var handlers = {
  TagNeedleEchoWrapper: Fn.new{|content| "echo.call(%(content))"}
}

var Preprocess = Fn.new {|content, index, needle, needleEnd|

    var start = content.indexOf(needle, index)
    index = start

    var end = content.indexOf(needleEnd, start)
    var code = content[start + needle.count...end]

    var eval = code
    if (handlers[needle]) {
      eval = handlers[needle].call(code)
    }

    // Execute the code contents
    Meta.compile(eval).call()

    // Build the final echo string
    var out = echoes_.join("").toString

    // Reset echo item bag
    // So the output of each tag is isolated
    echoes_ = []

    return [content.replace(needle + code + needleEnd, out), index]
}

var ReplaceTags = Fn.new{|content, needle, needleEnd|
  // Search for all instances of tags
  var tagCount = content.split(needle).count - 1
  var processed = 0
  var index = 0
  var result = null

  // Preprocess each tag until done
  while (processed < tagCount) {
      result = Preprocess.call(content, index, needle, needleEnd)
      content = result[0].trimStart()
      index = result[1]
      processed = processed + 1

      // Clean echo bag just to be sure
      echoes_ = []
  }
  return content
}

var import_ = Fn.new {|path|
  var extension_ = "." + TagExtension
  var content = File.read(path + extension_)
  content = ReplaceTags.call(content, TagNeedle, TagNeedleEnd)
  content = ReplaceTags.call(content, TagNeedleEchoWrapper, TagNeedleEnd)
  return content
}

// Include a file inside themes using this function
var include = Fn.new{|path| import_.call("./themes/%(Config.theme)/" + path)}

// Require a file inside the content/directory path using this function
var require = Fn.new{|name| import_.call(Path + "/" + name)}

// Content Helpers
class Content {
  static read(file) {
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
    var content = Content.read(file)
    content = ReplaceTags.call(content, TagNeedle, TagNeedleEnd)
    content = ReplaceTags.call(content, TagNeedleEchoWrapper, TagNeedleEnd)
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

// This will be available inside templates using this object
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

var out = include.call(tpl)
var outname = Path.replace("content/", "") + ".html"
var outpath = Config.out + "/" + outname

var rendered = File.create(outpath)
rendered.writeBytes(out)
