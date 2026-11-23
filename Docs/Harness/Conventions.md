# Conventions

## Escopo

- **Sim:** sintaxe válida? onde está o erro? qual a árvore genérica? como imprimir canonicamente?
- **Não:** validar se `Button` pode ter certo filho; registry de componentes/triggers/actions; render nativo; runtime de eventos; **expand / furos `#{Name}`** (isso é backend Rust).

Não coloque validação NShiftUI neste pacote. Não implemente substituição de templates; o payload mobile chega concreto.

## Regra do DSL

```text
() = parâmetros / configuração
{} = composição, filhos e fluxo
```

Parâmetros são nomeados: `Button(title: "Entrar", variant: .primary)`.

Não usar nós aninhados como valor de parâmetro nesta versão:

```rainbow
# inválido no escopo atual
Button(label: Text(value: "Entrar"))
```

Composição via blocks.

## Gramática concreta

A [especificação compartilhada](https://github.com/NShiftUI-OSS/RainbowParser-Rust/blob/main/spec/grammar.md) documenta os pins `use`, os modificadores, as listas de plugins e os corpos `@LANG`. Um nó com filhos e sem parâmetros é escrito `Screen { Spinner() }`. O parser preserva os comentários de linha associados ao próximo elemento.

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
