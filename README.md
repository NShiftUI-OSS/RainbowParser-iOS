# RainbowParser

`RainbowParser` is the syntax package for the Rainbow DSL.

Rainbow is a textual DSL designed to describe native SDUI payloads in a shape that feels closer to SwiftUI and Jetpack Compose than JSON. This package is intentionally focused on syntax only: it reads Rainbow source into a generic Swift AST and prints that AST back to canonical Rainbow text.

The semantic meaning of nodes such as `Screen`, `Button`, `OnTap` or `SendHTTPRequest` belongs to `NShiftUI`, not to this package.

## Version

Current beta:

```text
0.1.0-beta.1
```

Runtime version is exposed as:

```swift
RainbowParserVersion.current
```

Swift Package Manager resolves package releases from Git tags. To publish this exact beta version, tag the repository with:

```bash
git tag 0.1.0-beta.1
git push origin 0.1.0-beta.1
```

## Requirements

- Swift 6.3 or newer
- macOS with Xcode toolchain available
- Swift Package Manager

The package is configured with:

```swift
// swift-tools-version: 6.3
swiftLanguageModes: [.v6]
```

## What This Package Does

`RainbowParser` provides:

- Lexer for Rainbow source text.
- Parser for named nodes, named parameters, blocks and values.
- Generic AST types for syntax-level representation.
- Canonical printer for encoding AST back to Rainbow source.
- Structured diagnostics with source locations.
- Public decode/encode facade.
- `Sendable` public models suitable for concurrent use.
- Typed throws via `throws(RainbowParseError)`.

The core pipeline is:

```text
String Rainbow
-> RainbowLexer
-> [RainbowToken]
-> RainbowSyntaxParser
-> RainbowDocument
-> RainbowPrinter
-> String Rainbow
```

## What This Package Does Not Do

`RainbowParser` does not validate NShiftUI semantics.

It does not know whether:

- `Button` is a component.
- `OnTap` is a trigger.
- `SendHTTPRequest` is an action/event.
- `Screen` must be the root node.
- A node accepts another node as a child.

Those rules must be implemented by `NShiftUI`, probably in its services/domain layer, using the generic `RainbowDocument` produced here.

## DSL Rules For This Beta

The v0.1 beta follows one central rule:

```text
() = parameters/configuration
{} = composition, children and flow
```

Example:

```rainbow
Screen(name: "Home") {
  Button(title: "Entrar", variant: primary) {
    OnTap {
      SendHTTPRequest(method: post, url: "/login") {
        OnSuccess {
          Navigate(to: "Dashboard")
        }
      }
    }
  }
}
```

Parameters are named:

```rainbow
Button(title: "Entrar", variant: primary)
```

This beta does not support plugins, components, triggers or events as inline parameter values:

```rainbow
Button(label: Text(value: "Entrar"))
```

Composition should be represented through blocks instead.

## Supported Syntax

High-level grammar:

```text
Document   = Node*
Node       = Identifier Arguments? Block?
Arguments  = "(" ParameterList? ")"
Parameter  = Identifier ":" Value
Block      = "{" Node* "}"
Value      = String | Number | Bool | Identifier | Array | Object | Null
Object     = "(" (ObjectEntry ("," ObjectEntry)*)? ")"
```

Supported values:

```rainbow
Node(
  text: "value",
  int: -1,
  double: 1.25,
  enabled: true,
  disabled: false,
  variant: primary,
  items: ["a", 1, null],
  meta: (id: "home", "dash-key": false),
  emptyArray: [],
  emptyObject: ()
)
```

## Public API

The main facade is `RainbowParser`:

```swift
import RainbowParser

let source = """
Button(title: "Entrar") {
  OnTap {
    Navigate(to: "Home")
  }
}
"""

let parser = RainbowParser()
let document = try parser.decode(source)
let encoded = parser.encode(document)
```

You can also use the explicit decoder and encoder:

```swift
let document = try RainbowDecoder().decode(source)
let encoded = RainbowEncoder().encode(document)
```

Decode uses typed throws:

```swift
do {
    let document = try RainbowDecoder().decode(source)
} catch {
    for diagnostic in error.diagnostics {
        print(diagnostic.description)
    }
}
```

## AST Model

The parser returns generic syntax types:

```swift
RainbowDocument
RainbowNode
RainbowBlock
RainbowParameter
RainbowValue
RainbowObjectEntry
```

Example source:

```rainbow
Button(title: "Entrar") {
  OnTap {
    Navigate(to: "Home")
  }
}
```

Conceptual AST:

```text
RainbowDocument
  RainbowNode "Button"
    parameter title = "Entrar"
    block
      RainbowNode "OnTap"
        block
          RainbowNode "Navigate"
            parameter to = "Home"
```

`RainbowNode` keeps `block` separate from `children` so the printer can distinguish:

```rainbow
Navigate(to: "Home")
```

from:

```rainbow
OnTap {}
```

## Project Structure

```text
Sources/
  RainbowParser/
    AST/
    Diagnostics/
    Lexer/
    Parser/
    Printer/
    Public/
    Support/

Tests/
  RainbowParserTests/
    ASTTests.swift
    LexerTests.swift
    ParserTests.swift
    PrinterTests.swift
    RoundTripTests.swift
```

### AST

Generic syntax-level Swift models. These types do not know about `NShiftUI`.

### Diagnostics

Structured parser and lexer errors with source range, line and column.

### Lexer

Transforms source characters into Rainbow tokens.

### Parser

Transforms tokens into `RainbowDocument`.

### Printer

Transforms `RainbowDocument` back into canonical Rainbow source.

### Public

Public facade types used by consumers of the package.

### Support

Internal scanner and source text utilities.

## Canonical Encoding

The encoder does not preserve original spacing or formatting. It prints canonical Rainbow.

Input:

```rainbow
Button( title:"Entrar"){OnTap{Navigate(to:"Home")}}
```

Output:

```rainbow
Button(title: "Entrar") {
  OnTap {
    Navigate(to: "Home")
  }
}
```

This is intentional for the beta. Lossless round-trip formatting, comments and trivia preservation are out of scope for `0.1.0-beta.1`.

## Thread Safety And Concurrency

Public models are immutable value types and conform to `Sendable`.

`RainbowParser`, `RainbowDecoder` and `RainbowEncoder` do not keep shared mutable state. Each decode creates fresh lexer/parser state, so the parser can be used from concurrent tasks.

The test suite includes concurrent parsing coverage.

## Running Tests

Run the test suite with SwiftPM:

```bash
swift test
```

Run with code coverage:

```bash
swift test --enable-code-coverage
```

Generate a coverage report:

```bash
xcrun llvm-cov report \
  .build/arm64-apple-macosx/debug/RainbowParserPackageTests.xctest/Contents/MacOS/RainbowParserPackageTests \
  -instr-profile .build/arm64-apple-macosx/debug/codecov/default.profdata \
  -ignore-filename-regex Tests
```

Current validated result:

```text
40 tests passed
100% regions
100% functions
100% lines
```

## Test Coverage

The suite covers:

- AST initialization and block semantics.
- Lexer tokens, literals, whitespace, CRLF, escapes and invalid characters.
- Parser nested nodes, values, arrays, objects and syntax diagnostics.
- Printer canonical output and escaping.
- Diagnostics formatting.
- Round-trip structure preservation.
- Concurrent parser usage.

## Xcode Scheme

This repository is a pure Swift Package.

There is no versioned `.xcscheme` committed in the repository. Xcode generates a local package scheme automatically when opening `Package.swift`.

Recommended command-line flow:

```bash
swift test
```

In Xcode:

1. Open `Package.swift`.
2. Select the generated package scheme, usually named `RainbowParser-Package` or similar.
3. Run tests with `Command + U`.

For GitLab CI, prefer `swift test` over a manually maintained Xcode scheme unless the project later needs iOS simulator specific testing.

## GitLab CODEOWNERS

The project includes a root `CODEOWNERS` file:

```text
* @arthur.porto
```

This makes GitLab assign project ownership for all files to the configured user.

## Release Scope

Included in `0.1.0-beta.1`:

- Syntax AST.
- Lexer.
- Parser.
- Printer.
- Diagnostics.
- Public decode/encode API.
- Tests and coverage.
- CODEOWNERS.

Out of scope:

- NShiftUI semantic validation.
- Component/trigger/action registry.
- Plugin resolution.
- Macros.
- Expressions.
- Conditionals.
- Loops.
- Lossless formatting.
- Comments.

## Intended Integration With NShiftUI

The intended dependency direction is:

```text
NShiftUI -> RainbowParser
RainbowParser -> no dependency on NShiftUI
```

Expected integration flow:

```text
Rainbow source
-> RainbowParser
-> RainbowDocument
-> NShiftUI semantic decoder
-> NShiftUI domain tree
-> native rendering/runtime
```

The reverse flow:

```text
NShiftUI domain tree
-> NShiftUI semantic encoder
-> RainbowDocument
-> RainbowParser encoder
-> Rainbow source
```

## Development Notes

Keep this package focused on syntax.

Good responsibilities for `RainbowParser`:

- "Is this valid Rainbow syntax?"
- "Where is the syntax error?"
- "What is the generic tree?"
- "How do we print this tree canonically?"

Responsibilities that should stay outside this package:

- "Can a `Button` contain this child?"
- "Is `OnTap` allowed here?"
- "Is `SendHTTPRequest` registered?"
- "What native view does this node render?"
- "How should runtime events execute?"

## License

Internal project license is not declared in this beta.
