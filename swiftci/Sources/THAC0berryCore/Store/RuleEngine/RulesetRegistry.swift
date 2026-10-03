import Foundation

/// O motor central de regras — todo cálculo de jogo que precisa ser
/// consistente em mais de um lugar (a ficha, uma futura tela de
/// consequências, um suplemento alternativo) passa por aqui, em vez de
/// morar dentro de uma View. Ver TODO.md item 11 pro raciocínio completo
/// por trás da arquitetura.
///
/// `ObservableObject` e injetado como `@EnvironmentObject`, mesmo padrão de
/// `RulesDatabase`/`KitDatabase` — mesmo hoje sem nenhum estado que mude em
/// runtime (só o Core ativo), deixa pronto pro dia em que trocar o módulo
/// ativo de uma campanha (Dark Sun ligado/desligado) precisar atualizar a
/// UI sozinho.
final class RulesetRegistry: ObservableObject {
    /// Módulos ativos, do MAIS pro MENOS prioritário. O Core fica sempre
    /// por último — é o piso: toda `key` que nenhum suplemento cobrir cai
    /// nele. Suplementos futuros entram na FRENTE desta lista quando
    /// ativados (ver `activate`), então uma regra deles vence a
    /// equivalente do Core automaticamente, sem exigir que o Core saiba
    /// que eles existem.
    @Published private(set) var activeModules: [RulesetModule]

    init(modules: [RulesetModule] = [CoreRuleset()]) {
        self.activeModules = modules
    }

    /// Liga um módulo (ex. Dark Sun quando uma campanha usa esse cenário).
    /// Vai pro topo da prioridade — sobrescreve o Core em qualquer `key`
    /// que ele também responda. Reativar um módulo já ativo só move ele
    /// pro topo de novo (idempotente, sem duplicar).
    func activate(_ module: RulesetModule) {
        activeModules.removeAll { $0.id == module.id }
        activeModules.insert(module, at: 0)
    }

    /// Desliga um módulo pelo id — o Core (id "core") ignora a chamada:
    /// ele é o piso, não devia dar pra desligar sem outro módulo pra
    /// assumir o lugar.
    func deactivate(id: String) {
        guard id != CoreRuleset.moduleID else { return }
        activeModules.removeAll { $0.id == id }
    }

    /// Resolve uma `key` lógica pra um retrato de personagem, perguntando
    /// aos módulos ativos em ordem de prioridade — o primeiro provider que
    /// responder (valor não-`nil`) vence. Devolve também o provider que
    /// respondeu, pra quem chamou saber o rótulo/regra de origem sem uma
    /// segunda busca.
    func resolve(key: String, context: RuleContext) -> (value: RuleValue, provider: RuleProvider)? {
        for module in activeModules {
            for provider in module.providers where provider.key == key {
                if let value = provider.compute(for: context) {
                    return (value, provider)
                }
            }
        }
        return nil
    }
}
