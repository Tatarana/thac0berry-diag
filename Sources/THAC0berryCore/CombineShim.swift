// Combine (de onde vêm `ObservableObject`/`@Published`) só existe nas
// plataformas da Apple — no toolchain Swift open-source pra Linux (usado
// aqui só pra conseguir uma mensagem de erro REAL do compilador) esse
// módulo não existe, e o `swift build` travava em "no such module
// 'Combine'" antes mesmo de chegar nos arquivos que a gente queria
// testar de verdade. Esse shim só entra em cena quando Combine NÃO está
// disponível (`#if canImport`), então no app de verdade (iOS/Swift
// Playgrounds) nada disso é usado — continua sendo o Combine real.
#if !canImport(Combine)
public protocol ObservableObject: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    public var projectedValue: Published<Value> { self }
}
#endif
