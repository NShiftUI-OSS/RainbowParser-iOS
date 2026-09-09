# Architecture

## Papel

`RainbowParser` é a camada de **sintaxe** do DSL Rainbow. Converte texto ↔ AST genérica.
Não conhece componentes, triggers ou actions do NShiftUI.

## Pipeline

```text
String (Rainbow)
  → RainbowLexer          (Support/CharacterScanner + SourceText)
  → [RainbowToken]        (Lexer/RainbowToken + RainbowTokenKind)
  → RainbowSyntaxParser
  → RainbowDocument       (AST)
  → RainbowPrinter        (Printer + RainbowFormatStyle)
  → String (canônico)
```

Facades públicas:

- `RainbowDecoder.decode` — Lexer + SyntaxParser
- `RainbowEncoder.encode` — Printer
- `RainbowParser` — decode + encode

## Módulos internos (`Sources/RainbowParser/`)

| Pasta | Responsabilidade |
|-------|------------------|
| `Public/` | Facades e versão |
| `Lexer/` | Tokens a partir do source |
| `Parser/` | Tokens → `RainbowDocument` |
| `AST/` | Modelos sintáticos imutáveis |
| `Printer/` | AST → texto canônico |
| `Diagnostics/` | Erros, ranges, severidade |
| `Support/` | Scanner e texto (interno) |

## Concorrência

Modelos públicos são value types `Sendable`. Facades não guardam estado mutável compartilhado; cada decode cria estado fresco de lexer/parser.

## Integração pretendida

```text
Rainbow source → RainbowParser → RainbowDocument
  → (NShiftUI semantic layer) → domain tree → render
```

Inverso: domain → semantic encoder → `RainbowDocument` → `RainbowEncoder` → source.

`NShiftUIKitServices` declara o produto `RainbowParser` no `Package.swift`, mas ainda **não** importa o módulo no código.
