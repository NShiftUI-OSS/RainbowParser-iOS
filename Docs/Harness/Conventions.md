# Conventions

## Escopo

- **Sim:** sintaxe válida? onde está o erro? qual a árvore genérica? como imprimir canonicamente?
- **Não:** validar se `Button` pode ter certo filho; registry de componentes/triggers/actions; render nativo; runtime de eventos.

Não coloque validação NShiftUI neste pacote.

## Regra do DSL (beta)

```text
() = parâmetros / configuração
{} = composição, filhos e fluxo
```

Parâmetros são nomeados: `Button(title: "Entrar", variant: primary)`.

Não usar nós aninhados como valor de parâmetro neste beta:

```rainbow
# inválido no escopo atual
Button(label: Text(value: "Entrar"))
```

Composição via blocks.

## Gramática (alto nível)

```text
Document   = Node*
Node       = Identifier Arguments? Block?
Arguments  = "(" ParameterList? ")"
Parameter  = Identifier ":" Value
Block      = "{" Node* "}"
Value      = String | Number | Bool | Identifier | Array | Object | Null
Object     = "(" (ObjectEntry ("," ObjectEntry)*)? ")"
```

Trailing commas em arrays são aceitos. Em parâmetros e entradas de objeto, não.

## Código Swift

- Swift 6 (`swiftLanguageModes: [.v6]`), sem deps externas.
- Públicos: imutáveis, `Equatable` + `Sendable` onde aplicável.
- Erros de parse: `throws(RainbowParseError)`.
- Tokens/lexer/parser/printer de implementação: não `public`.
- Preferir `swift test` após mudanças; manter cobertura alta.

## Encode

Saída canônica. Round-trip preserva **estrutura**, não formatação original.

## Commits / harness

Não commitar/push a menos que o usuário peça. Atualizar harness via `update-harness` quando a superfície mudar.
