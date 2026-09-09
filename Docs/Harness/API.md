# API pública

Todas as superfícies abaixo são `Sendable` (value types / enums). Decode usa typed throws.

## Facades

```swift
import RainbowParser

let parser = RainbowParser()
let document = try parser.decode(source)          // throws(RainbowParseError)
let encoded = parser.encode(document)             // canônico
let encoded2 = parser.encode(document, style: .default)

let document2 = try RainbowDecoder().decode(source)
let encoded3 = RainbowEncoder().encode(document2)
let encoded4 = RainbowEncoder(style: RainbowFormatStyle(indentation: "\t")).encode(document2)
```

Versão: `RainbowParserVersion.current` → `"0.1.0-beta.1"`.

## AST

| Tipo | Campos / casos |
|------|----------------|
| `RainbowDocument` | `uses: [RainbowUseDeclaration]`, `nodes: [RainbowNode]` |
| `RainbowUseDeclaration` | `name`, `version` — `use Screen@1.0.0` (opcional; pin SemVer) |
| `RainbowNode` | `name`, `parameters`, `block?`; computed `children`, `hasBlock` |
| `RainbowBlock` | `children: [RainbowNode]` |
| `RainbowParameter` | `name: String`, `value: RainbowValue` |
| `EmbeddedLanguage` | `json` / `yaml` / `xml` / `html` / `markdown` (`JSON`…`MARKDOWN` in source) |
| `RainbowTaggedBody` | `.text(String)` \| `.placeholder(String)` — body of `@LANG(...)` |
| `RainbowObjectEntry` | `key: String`, `value: RainbowValue` |
| `RainbowValue` | `.string`, `.int`, `.double`, `.bool`, `.identifier`, `.array`, `.object`, `.null`, `.tagged(language:body:bodyRange:)` |

`RainbowNode` mantém `block` separado de `children` para o printer distinguir `Navigate(to: "Home")` de `OnTap {}`.

## Diagnostics

| Tipo | Papel |
|------|--------|
| `RainbowParseError` | `diagnostics: [RainbowDiagnostic]`; `CustomStringConvertible` |
| `RainbowDiagnostic` | `code`, `message`, `severity`, `range` |
| `RainbowDiagnosticSeverity` | `.error`, `.warning` |
| `RainbowSourceLocation` | line/column (Comparable) |
| `RainbowSourceRange` | start/end |

```swift
do {
    _ = try RainbowDecoder().decode(source)
} catch {
    for d in error.diagnostics { print(d.description) }
}
```

## Format

`RainbowFormatStyle`: `indentation` (default `"  "`), `newline` (default `"\n"`).
Encode força blank entre irmãos e preserva leading `//` em `use` / nós / parâmetros.
Corpos `@LANG` multilinha são reindentados (sem pretty-print de linguagem no Swift).

## Interno (não público)

`RainbowLexer`, `RainbowToken`, `RainbowTokenKind`, `RainbowSyntaxParser`, `RainbowPrinter`, `CharacterScanner`, `SourceText`.
