# Decisions

## D1 — Sintaxe sem semântica

**Decisão:** este pacote não interpreta nomes de nós (`Screen`, `Button`, …).

**Por quê:** separa parser reutilizável da camada de domínio NShiftUI; evita acoplamento circular.

**Consequência:** consumidores devem validar/registry em outro módulo.

## D2 — `()` vs `{}`

**Decisão:** parâmetros em `()`; filhos/fluxo em `{}`.

**Por quê:** alinhamento com sensação SwiftUI/Compose e regra única no beta.

## D3 — Encode canônico (com leading trivia)

**Decisão:** printer normaliza indentação/espaços e força linha em branco entre
irmãos. Comentários `//` de linha inteira imediatamente antes de `use` / nó /
parâmetro são preservados (leading trivia). Comentários no fim da mesma linha
que código ficam fora do v1.

**Por quê:** escopo `0.1.0-beta.1`; round-trip estrutural é suficiente.

## D4 — Zero dependências

**Decisão:** `Package.swift` sem `dependencies`.

**Por quê:** pacote de fundação; SPM puro; fácil de consumir.

## D5 — Facades + internos

**Decisão:** API pública via `RainbowParser` / Decoder / Encoder / AST / diagnostics; lexer/parser/printer internals.

**Por quê:** permite evoluir implementação sem quebrar consumidores.

## D6 — Typed throws + diagnostics estruturados

**Decisão:** `throws(RainbowParseError)` com lista de `RainbowDiagnostic` e source ranges.

**Por quê:** erros acionáveis para IDEs/CI e tipagem Swift 6.

## D7 — Integração NShiftUIKit adiada no código

**Decisão:** `NShiftUIKitServices` declara o produto, mas ainda não `import RainbowParser`.

**Por quê:** dependência preparada; wiring semântico ainda não aterrissou.

## Fora de escopo (beta)

Plugins, macros, expressões, condicionais, loops, trailing end-of-line comments, registry semântico, pretty-print embutido de `@LANG` (Rust-only).
