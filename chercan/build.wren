#!/usr/bin/env wren

import "os" for Process
import "io" for File
import "meta" for Meta

import "./config" for Config

var path = Process.arguments[0]
var filename = path + ".wren"

System.print("Processing " + filename)

if (!File.exists(filename)) {
  Fiber.abort("File %(path) does not exists")
}

var page = Meta.compile(File.read(filename)).call()

var extension = ".wren.html"
var theme = "./themes/%(Config.theme)/"

var include = Fn.new{|path|
  var body_ = File.read(theme + path + extension)
  return Meta.compile(body_).call().toString
}

var tpl = Config.template.default
Fiber.new {tpl = page.template}.try()

var out = include.call(tpl)
var outname = path.replace("content/", "") + ".html"
var outpath = Config.out + "/" + outname

var rendered = File.create(outpath)
rendered.writeBytes(out)

