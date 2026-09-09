---
name: update-harness
description: Remaps this repository's AI harness (AGENTS.md + Docs/Harness) from the live codebase. Use after architecture/API/module changes, or when the user asks to update/refresh/remap the harness.
---

# update-harness

Remapeia o harness de agentes a partir do código vivo deste pacote. Use quando Sources, Tests, `Package.swift` ou `README.md` mudarem — ou quando o usuário pedir para atualizar o harness.

## Objetivo

Manter `AGENTS.md` + `Docs/Harness/` alinhados à verdade do repositório, com progressive disclosure e baixo custo de tokens.

## Escopo

**Escrever apenas** dentro da raiz do pacote `rainbowparser`.

**Não** alterar lógica de `Sources/` ou `Tests/` (salvo se o usuário pedir correção de produto em outra tarefa).

**Não** commit/push a menos que o usuário peça explicitamente.

## Fontes de verdade (ler de verdade)

1. `Package.swift` — produtos, targets, deps, Swift mode
2. `Sources/RainbowParser/**` — API pública vs interna, pipeline
3. `Tests/RainbowParserTests/**` — contagem e focos de teste
4. `README.md` — versão, regras DSL, integração (destilar, não copiar)
5. Consumidores no monorepo (se acessível): quem declara/importa `RainbowParser`

## Passos

1. **Inventariar**
   - Listar arquivos em Sources/Tests
   - Extrair tipos `public`
   - Contar `@Test`
   - Confirmar versão (`RainbowParserVersion.current` / README)
   - Confirmar deps (deve permanecer zero no Package)

2. **Atualizar profundidade** (`Docs/Harness/`)
   - `INDEX.md` — índice e quando abrir cada doc
   - `Architecture.md` — pipeline e pastas
   - `Map.md` — path → responsabilidade
   - `API.md` — superfície pública e contratos
   - `Conventions.md` — regras DSL e limites
   - `Decisions.md` — só se houver decisão nova/mudada
   - `Update.md` — entrada datada do que mudou no harness

3. **Manter `AGENTS.md` curto (≤120 linhas)**
   - Identidade, ordem de leitura, comandos, ecossistema, princípios, ponteiro update-harness, cross-tool
   - Destilar README; não duplicar exemplos longos
   - Enfatizar: sem validação NShiftUI aqui

4. **Preservar bridges**
   - `CLAUDE.md` → `AGENTS.md` (symlink)
   - `.cursor/skills/update-harness` → `../../Agents/UpdateHarness`
   - `.claude/skills/update-harness` → `../../Agents/UpdateHarness`
   - `.agents/skills/update-harness` → `../../Agents/UpdateHarness`
   - `.cursor/rules/harness.mdc` (`alwaysApply: true`)
   - `.claude/commands/update-harness.md`
   - Recriar symlinks se quebrados
   - **APFS:** nunca fazer rename só de case (`docs`→`Docs`); criar pastas PascalCase fresh

5. **Verificar**
   - Symlinks resolvem
   - Contagens/versão/API batem com o código
   - Nenhum segredo/local override commitado

6. **Changelog** — append em `Docs/Harness/Update.md`

## Estilo

- Prosa em **português**; identificadores em inglês
- Tabelas curtas; links relativos
- Preferir apontar para código a reescrever o README

## Saída esperada

Lista dos paths tocados + confirmação de symlinks + resumo do que mudou no mapa/API.
