import Foundation

/// Uma folha de magias — uma por dia de jogo.
///
/// Esta é a diferença central em relação à ficha do personagem: em AD&D 2e
/// os slots zeram no repouso, então a memorização não é um atributo
/// permanente do personagem, e sim o preenchimento de um dia. Guardar uma
/// folha por dia mantém o histórico da campanha inteira: dá para folhear e
/// ver o que o clérigo levava preparado no dia em que o grupo caiu na
/// emboscada.
struct SpellSheet: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date = Date()
    /// A sessão de mesa (data real) a que esse dia pertence. `nil` só em
    /// folhas de uma versão anterior a Sessão — `migrateLegacySheetsIfNeeded`
    /// resolve isso na primeira leitura.
    var sessionID: UUID? = nil
    /// Como você chama esse dia na mesa ("3º dia em Elturel").
    var title: String = ""
    /// Os slots e o que foi memorizado neles neste dia.
    var slotBoard = SpellSlotBoard()
    /// O que foi efetivamente conjurado ao longo do dia.
    var entries: [SpellLogEntry] = []
    /// Itens mágicos (anéis, cajados, bastões, armaduras...) — cada um pode
    /// ter mais de uma magia atrelada, com cargas do próprio item, não os
    /// slots de memorização do personagem, então vivem à parte da grade de
    /// círculos.
    var magicItems: [MagicItem] = []
    /// Anotações livres do dia, escritas à mão.
    var inkNotes: Data? = nil
    /// A Sabedoria do personagem no momento em que esta folha foi criada.
    /// Fica congelada aqui de propósito: se o personagem ganhar Sabedoria
    /// depois (item, ajuste), uma folha de uma data passada não deve mudar
    /// retroativamente — ela mostra a Sabedoria que valia naquele dia.
    var wisdomAtCreation: Int = 10
    /// Quantas vezes o clérigo já tentou expulsar mortos-vivos hoje. Sem
    /// teto — em 2e a tentativa de Turn Undead não é limitada por dia,
    /// só o resultado da rolagem é que decide se funciona.
    var turnUndeadUsed: Int = 0

    var displayTitle: String {
        if !title.isEmpty { return title }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    /// Círculos que existem nesta folha, em ordem, por tipo de conjurador.
    func levels(for caster: CasterType) -> [Int] {
        var found: [Int] = []
        for slot in slotBoard.slots where slot.caster == caster {
            if !found.contains(slot.level) { found.append(slot.level) }
        }
        return found.sorted()
    }

    /// Uma folha nova para o dia seguinte, herdando a mesma quantidade de
    /// slots (e, se você quiser, a mesma lista memorizada) — que é como se
    /// faz na mesa: no repouso você reprepara a partir do que tinha ontem.
    func nextDay(keepingPreparations: Bool) -> SpellSheet {
        var sheet = SpellSheet()
        sheet.slotBoard = slotBoard
        sheet.slotBoard.rest(clearingPreparations: !keepingPreparations)
        // Ids novos: dois dias não podem ter slots com a mesma identidade,
        // ou uma busca por id casaria na folha errada.
        for index in sheet.slotBoard.slots.indices {
            sheet.slotBoard.slots[index].id = UUID()
        }
        sheet.entries = []

        // As tentativas de hoje voltam a zero, como qualquer outra coisa
        // que o descanso reseta.
        sheet.turnUndeadUsed = 0

        // Os itens continuam os mesmos de um dia pro outro, mas as cargas
        // usadas de cada magia voltam a zero — é o que o descanso também
        // faz para eles.
        sheet.magicItems = magicItems.map { item in
            var copy = item
            copy.id = UUID()
            copy.spells = item.spells.map { spell in
                var freshSpell = spell
                freshSpell.id = UUID()
                freshSpell.usedCount = 0
                return freshSpell
            }
            return copy
        }

        return sheet
    }
}

/// Um item mágico (anel, cajado, bastão, armadura encantada...) que pode
/// conjurar uma ou mais magias, cada uma com sua própria carga. Guarda
/// também uma descrição curta do item, para consulta rápida sem precisar
/// procurar no livro.
struct MagicItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    /// Item 1 do pedido do usuário (2026-09-27): "Item" passou a também
    /// listar os itens do catálogo (`MagicItemDatabase`, mesma base da aba
    /// Equipment/página 2), sem obrigar a escolha de um existente — igual
    /// ao padrão já usado em `MagicItemQuantifiedRow`. `nil` quando o nome
    /// foi digitado à mão (item caseiro) ou numa ficha salva antes desta
    /// versão.
    var matchedItemID: String? = nil
    /// Texto livre — o que o item faz, propriedades, aparência. Só
    /// relevante quando `matchedItemID` é `nil`: um item ligado ao
    /// catálogo mostra a descrição de lá (`MagicItemDetailSheet`), não
    /// esta.
    var itemDescription: String = ""
    var spells: [ItemSpellUse] = []
}

/// Uma magia conjurada a partir de um item mágico. Usa cargas do próprio
/// item, não um slot de memorização — por isso tem seu próprio contador de
/// uso, separado do dos outros feitiços do mesmo item.
struct ItemSpellUse: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var spellName: String = ""
    /// Magia da base embutida, quando reconhecida — usada para abrir a
    /// descrição completa.
    var matchedSpellID: String? = nil
    /// Dano ou cura do item, como texto livre ("1d6+1", "2d4 fire") — o
    /// item pode ter um valor diferente do da magia "de livro".
    var damageNote: String = ""
    /// Teto de cargas — impede riscar além do que o item tem. Editável,
    /// não é desenhado como marcas prontas: só limita até onde o traço vai.
    var maxUses: Int = 20
    /// Quantos traços já foram feitos — cada arrasto na área em branco soma
    /// um, como um risco na parede feito à mão, não uma bolinha preenchida.
    var usedCount: Int = 0

    /// Um novo traço na conta — para no teto de cargas do item.
    mutating func addTally() {
        guard usedCount < maxUses else { return }
        usedCount += 1
    }

    /// Apaga o último traço — o mesmo toque simples na área da contagem.
    mutating func removeLastTally() {
        guard usedCount > 0 else { return }
        usedCount -= 1
    }
}

/// Uma magia adicional lançada fora da grade de círculos — o jeito de
/// registrar aquele "passar rápido" vários dias (3 dias hospedado em
/// segurança curando o grupo com magia, uma Regeneration de longa
/// duração) sem precisar escolher slot por slot em cada um desses dias.
/// Não risca nenhum slot memorizado — é só um registro à parte.
struct SpellLogEntry: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    /// Texto vindo da escrita com a Apple Pencil, antes de qualquer correção.
    var rawText: String = ""
    /// Magia da base embutida, quando o casamento foi confirmado.
    var matchedSpellID: String? = nil
    /// Nome final exibido — vem da magia casada ou do texto corrigido.
    var displayName: String = ""
    var spellLevel: Int? = nil
    /// Quantas vezes essa mesma magia foi conjurada nessa linha — um traço
    /// por conjuração, igual à contagem de Turn Undead, em vez de uma linha
    /// nova pra cada lançamento repetido do mesmo feitiço.
    var castCount: Int = 1
}
