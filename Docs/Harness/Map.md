# Map — arquivos

## Package

| Path | Notas |
|------|--------|
| `Package.swift` | `swift-tools-version: 6.3`, product/target `RainbowParser`, tests `RainbowParserTests`, `swiftLanguageModes: [.v6]`, sem deps |
| `README.md` | Docs humanas (não duplicar no harness) |
| `CODEOWNERS` | `* @arthur.porto` |

## Sources

| Path | Tipo | Notas |
|------|------|--------|
| `Public/RainbowParser.swift` | public | Facade decode/encode |
| `Public/RainbowDecoder.swift` | public | Lexer → Parser |
| `Public/RainbowEncoder.swift` | public | Printer |
| `Public/RainbowParserVersion.swift` | public | `current = "0.1.0-beta.1"` |
| `AST/RainbowDocument.swift` | public | `nodes: [RainbowNode]` |
| `AST/RainbowNode.swift` | public | `name`, `parameters`, `block`; `children`/`hasBlock` |
| `AST/RainbowBlock.swift` | public | `children` |
| `AST/RainbowParameter.swift` | public | `name` + `RainbowValue` |
| `AST/RainbowValue.swift` | public | string/int/double/bool/identifier/array/object/null/tagged `@LANG` |
| `AST/EmbeddedLanguage.swift` | public | JSON/YAML/XML/HTML/MARKDOWN + tagged body |
| `AST/RainbowObjectEntry.swift` | public | `key` + `value` |
| `Lexer/RainbowLexer.swift` | internal | Scan de tokens |
| `Lexer/RainbowToken.swift` | internal | Token + range |
| `Lexer/RainbowTokenKind.swift` | internal | Kinds (não público) |
| `Parser/RainbowSyntaxParser.swift` | internal | Parse + sync de erros |
| `Printer/RainbowPrinter.swift` | internal | Encode canônico |
| `Printer/RainbowFormatStyle.swift` | public | indent/newline |
| `Diagnostics/*` | public | Diagnostic, ParseError, Location, Range, Severity |
| `Support/CharacterScanner.swift` | internal | Peek/advance |
| `Support/SourceText.swift` | internal | Buffer de source |

## Tests (40)

| Arquivo | Foco | ~count |
|---------|------|--------|
| `ASTTests.swift` | init, block, error description | 3 |
| `LexerTests.swift` | tokens, escapes, CRLF, erros | 13 |
| `ParserTests.swift` | nested, values, trailing commas, diagnostics/sync | 17 |
| `PrinterTests.swift` | canônico, values, style, facade, empty | 5 |
| `RoundTripTests.swift` | estrutura + concorrência | 2 |

## Harness

| Path | Papel |
|------|--------|
| `AGENTS.md` | Entrada curta |
| `Docs/Harness/` | Profundidade |
| `Agents/UpdateHarness/` | Skill canônica |
| `.cursor/`, `.claude/`, `.agents/` | Bridges |
