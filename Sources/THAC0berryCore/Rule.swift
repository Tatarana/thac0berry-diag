import Foundation

/// Uma entrada de regra extraída do Player's Handbook ou do Dungeon
/// Master's Guide (2ª edição) — cobre desde regras centrais ("Calculating
/// THAC0") até tabelas de referência isoladas ("Table 53: THAC0 by Level").
/// 274 entradas / 200 tabelas ao todo, vindas de um pipeline de extração
/// separado (fora do app) que gerou os JSONs originais em `rules_phb/` e
/// `rules_dmg/` — auditados e corrigidos manualmente antes de virar este
/// arquivo (2 tabelas com colunas duplicadas causando perda silenciosa de
/// dado, ~4 trechos de wikitext solto, 111 tabelas com cabeçalhos genéricos
/// "Col N" recuperados a partir do livro original).
///
/// AJUSTE (2026-09-25, pedido do usuário: "converter os dados embutidos de
/// código Swift pra JSON"): voltou a carregar de `Resources/rules.json`
/// via `Codable` — não por causa do bug histórico de decode (aquele era
/// só do `Kit`, já corrigido, ver `KitArmorRules.init(from:)`), mas porque
/// o literal Swift gigante (385 entradas espalhadas em ~28 arquivos
/// `EmbeddedRules_PartN.swift`, a técnica documentada abaixo) continuava
/// travando o ARCHIVE de distribuição do Swift Playgrounds mesmo dividido
/// em partes — a compilação de Release/Archive usa "whole module
/// optimization", que reconstrói tudo num único módulo de qualquer forma,
/// anulando o benefício da divisão em arquivos que só ajuda o build de
/// Debug/execução local. JSON lido em runtime não passa pelo
/// type-checker, então não tem esse limite.
struct RuleEntry: Identifiable, Hashable, Codable {
    let id: String
    let book: String // "PHB" ou "DMG"
    let chapterNumber: Int
    let chapterTitle: String
    let breadcrumbs: String
    let topic: String
    /// "core_rule" / "optional_rule" / "dm_guideline" / "table_reference".
    let ruleType: String
    let summary: String
    /// Prosa já em markdown leve (`##` pra subtítulo, `**negrito**`,
    /// `*itálico*`, `[TABLE_REF: Table N: Título]` como placeholder inline
    /// que deve resolver pra uma tabela em `tables` na mesma entrada —
    /// 100% consistente no corpus inteiro, verificado por auditoria).
    let content: String
    let tables: [RuleTable]
    let relatedRuleIds: [String]
    let relatedSpells: [String]
    let relatedMagicItems: [String]
    let searchKeywords: [String]

    var isFromDMG: Bool { book == "DMG" }

    /// Título curto pra listas — o `topic` já é a versão sem os
    /// breadcrumbs completos.
    var displayTitle: String { topic }
}

struct RuleTable: Identifiable, Hashable, Codable {
    /// "Table 53", "Table 10A" etc. — usado como parte do `id` porque não
    /// é garantidamente único sozinho entre livros diferentes.
    let tableNumber: String
    let title: String
    let headers: [String]
    /// Cada linha é um array posicional (mesma ordem de `headers`), não um
    /// dicionário — decisão deliberada pra evitar o bug de colisão de
    /// chave duplicada que já mordeu este dataset duas vezes (Table 10,
    /// Table 34: colunas repetidas tipo "Base"/"Modifier" pra Male/Female
    /// sobrescreviam uma a outra num dicionário). Todo valor já vem como
    /// String (números formatados sem sufixo `.0` quando inteiros) porque
    /// a extração original mistura `str`/`int`/`float` por célula e a
    /// única coisa que se faz com isso aqui é exibir num grid.
    let rows: [[String]]

    var id: String { tableNumber + ":" + title }
}
