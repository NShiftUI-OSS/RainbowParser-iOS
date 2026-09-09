# Harness UPDATE log

## 2026-07-09

- Recriação do harness com pastas PascalCase (`Docs/Harness`, `Agents/UpdateHarness`) após perda por rename em APFS case-insensitive.
- Conteúdo destilado do README + fatos verificados no código (`0.1.0-beta.1`, 40 testes, pipeline Lexer→Parser→AST→Printer, zero deps, NShiftUIKitServices declara sem import).
- Skill canônica `Agents/UpdateHarness` + bridges/symlinks (Cursor / Claude Code / Codex).
- `.gitignore`: overrides locais de agent.
