import Foundation

protocol NewsServiceProtocol {
    func fetchBits() async throws -> [Bit]
    func fetchBitsProgressively(onBatchReady: @escaping @MainActor ([Bit]) -> Void) async
    func fetchBits(for category: BitCategory) async throws -> [Bit]
    func searchBits(query: String) async throws -> [Bit]
}
