//
//  ViewModel.swift
//  code-challenge
//

import UIKit

protocol ViewModelProvider {
    
    func fetch() async throws -> [ViewModel.Section]
}

struct ViewModel: ViewModelProvider {
    
    struct Item: Hashable {
        let text: String
        let thumbnailURL: String?
    }
    
    enum Section: Hashable {
        case first([Item])
        case second(Item)
        
        var items: [Item] {
            switch self {
            case .first(let items):
                return items
            case .second(let item):
                return [item]
            }
        }
    }
    
    var networkRequestManager: NetworkRequestProvider = NetworkRequestManager()
    
    func fetch() async throws -> [ViewModel.Section] {
        let firstFeeds: [Feed] = try await [firstEndpoint, secondEndpoint].compactMap { URL(string: $0) }.asyncCompactMap { url in
            try await networkRequestManager.fetch(Feed.self, from: url)
        }
        var finalURL: URL?
        let firstItems: [ViewModel.Item] = firstFeeds.map { $0.models }.flatMap { $0 }.groupById().map { models in
            let text = models.sorted { $0.position < $1.position }.reduce("") { $0 + $1.text }
            let thumbnailURL = models.compactMap { $0.thumbnailURL }.first
            if text.hasPrefix("https://"), let url = URL(string: text) {
                finalURL = url
            }
            return ViewModel.Item(text: text, thumbnailURL: thumbnailURL)
        }
        
        guard let finalURL else {
            return [ViewModel.Section.first(firstItems)]
        }
        let finalFeeds: Model = try await networkRequestManager.fetch(Model.self, from: finalURL)
        return [ViewModel.Section.first(firstItems),
                ViewModel.Section.second(ViewModel.Item(text: finalFeeds.text, thumbnailURL: finalFeeds.thumbnailURL))]
    }
}

extension Sequence {
    // MARK: - CompactMap
    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            guard let newElement = try await transform(element) else { continue }
            values.append(newElement)
        }
        
        return values
    }
}

extension Array where Element == Model {
    func groupById() -> [[Model]] {
        var totalModels = [Int: [Model]]()
        self.forEach { model in
            if let models = totalModels[model.id] {
                var newModels = models
                newModels.append(model)
                totalModels[model.id] = newModels
            } else {
                totalModels[model.id] = [model]
            }
        }
        return totalModels.values.map { $0 }.sorted { ($0.first?.id ?? 0) > ($1.first?.id ?? 0) }
    }
}

extension Array {
    subscript (safe index: Index) -> Element? {
        return index >= 0 && count > index  ? self[index] : nil
    }
}
