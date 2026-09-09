# Harness Index — RainbowParser

Índice de progressive disclosure. Leia só o que a tarefa exige.

| Doc | Quando abrir |
|-----|----------------|
| [Architecture.md](./Architecture.md) | Entender pipeline Lexer→Parser→AST→Printer e pastas |
| [Map.md](./Map.md) | Localizar arquivo por responsabilidade |
| [API.md](./API.md) | Superfície pública e contratos de decode/encode |
| [Conventions.md](./Conventions.md) | Regras de DSL, estilo e o que não fazer |
| [Decisions.md](./Decisions.md) | Decisões de design e escopo beta |
| [Update.md](./Update.md) | Changelog do harness (não do produto) |

## Fontes de verdade

| Artefato | Papel |
|----------|--------|
| `Package.swift` | Produto, targets, Swift 6 |
| `Sources/RainbowParser/` | Implementação |
| `Tests/RainbowParserTests/` | Comportamento esperado (40 testes) |
| `README.md` | Documentação humana completa |
| `AGENTS.md` | Entrada curta para agentes |

## Atualização

Remapear com `Agents/UpdateHarness/SKILL.md` quando Sources/Tests/Package/README mudarem.
