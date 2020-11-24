
class Page {
  // Include any html render here
  static content {"
    <h2>Wren is a small, fast, class-based concurrent scripting language</h2>
    <hr />
    <p>Think Smalltalk in a Lua-sized package with a dash of Erlang and wrapped up in
    a familiar, modern syntax.</p>
    <pre>
System.print(\"Hello, world!\")

class Wren {
  flyTo(city) {
    System.print(\"Flying to \%(city)\")
  }
}

var adjectives = Fiber.new {
  [\"small\", \"clean\", \"fast\"].each {|word| Fiber.yield(word) }
}

while (!adjectives.isDone) System.print(adjectives.call())
    </pre>
  "}

  static title {"Welcome to Chercan Static Site Generator"}
}

return Page
