# RainbowParser — Agent Harness

Pacote Swift 6 de **sintaxe** do DSL Rainbow (SDUI textual). Versão `0.1.0-beta.1`.
Produto: `RainbowParser`. Zero dependências externas.

**Não** valida semântica NShiftUI (`Screen`, `Button`, `OnTap`, etc.). Isso vive em NShiftUI / NShiftUIKit.

## Ordem de leitura (progressive disclosure)

1. Este arquivo (`AGENTS.md`) — identidade e limites
2. `Docs/Harness/INDEX.md` — mapa do harness
3. Sob demanda: `Architecture`, `Map`, `API`, `Conventions`, `Decisions`
4. Código: `Sources/RainbowParser/`, `Tests/`, `Package.swift`, `README.md`

Não carregue o README inteiro na sessão; use `Docs/Harness/` e o código.

## Pipeline

```text
String → RainbowLexer → [RainbowToken] → RainbowSyntaxParser
      → RainbowDocument → RainbowPrinter → String
```

Regra central: `()` = parâmetros; `{}` = filhos / fluxo.

## API pública (resumo)

`RainbowParser`, `RainbowDecoder`, `RainbowEncoder`, `RainbowParserVersion`,
AST (`RainbowDocument`, `RainbowNode`, `RainbowBlock`, `RainbowParameter`,
`RainbowValue`, `RainbowObjectEntry`), diagnostics (`RainbowDiagnostic`,
`RainbowParseError`, ranges/locations), `RainbowFormatStyle`.

Detalhes: `Docs/Harness/API.md`.

## Comandos

```bash
swift build
swift test
swift test --enable-code-coverage
```

40 testes (AST, Lexer, Parser, Printer, RoundTrip). Cobertura forte.

## Ecossistema

```text
NShiftUIKitServices ──declara──► RainbowParser   (ainda sem import no código)
RainbowParser ──✗──► NShiftUI / NShiftUIKit
```

Direção correta: consumidor → parser. Semântica e render ficam fora daqui.

## Princípios

1. Sintaxe apenas — sem registry de componentes/triggers/actions.
2. AST genérica e `Sendable`; encode canônico (não lossless).
3. Typed throws: `throws(RainbowParseError)`.
4. Não alterar escopo beta: sem macros, expressões, condicionais, loops, comments.
5. Preferir testes + `swift test` após mudanças de sintaxe.

## Atualizar o harness

Skill remapeável: `Agents/UpdateHarness/SKILL.md`  
(Cursor / Claude Code / Codex via bridges em `.cursor/`, `.claude/`, `.agents/`).

Após mudanças em Sources/Tests/Package/README, rode o agent `update-harness`.

## Cross-tool

| Tool        | Entrada                         |
|-------------|---------------------------------|
| Cursor      | `AGENTS.md` + `.cursor/rules/`  |
| Claude Code | `CLAUDE.md` → `AGENTS.md`       |
| Codex       | `AGENTS.md` + `.agents/skills/` |

Overrides locais (gitignored): `AGENTS.local.md`, `CLAUDE.local.md`.
