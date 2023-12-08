//
//  ViewController.swift
//  code-challenge
//

import UIKit

class ViewController: UIViewController {
    
    var models: [ViewModel.Section]? {
        didSet {
            guard let models, !models.isEmpty else { return }
            DispatchQueue.main.async { [weak self] in
                var snapshot = NSDiffableDataSourceSnapshot<ViewModel.Section, ViewModel.Item>()
                snapshot.appendSections(models)
                models.forEach { snapshot.appendItems($0.items, toSection: $0) }
                self?.diffableDataSource?.apply(snapshot, animatingDifferences: true)
            }
        }
    }
    
    var diffableDataSource: UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout(sectionProvider: { section, _ in
            switch section {
            case 0:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(3.0/4.0),
                                                                          heightDimension: NSCollectionLayoutDimension.fractionalHeight(1.0)))
                let layoutSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0), heightDimension: NSCollectionLayoutDimension.absolute(300.0))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: layoutSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 0.0, leading: 10.0, bottom: 0.0, trailing: 0.0)
                return section
            case 1:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0), heightDimension: NSCollectionLayoutDimension.fractionalWidth(456.0/663.0)))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0), heightDimension: NSCollectionLayoutDimension.fractionalWidth(456.0/663.0)), subitems: [item])
                return NSCollectionLayoutSection(group: group)
            default:
                return nil
            }
        }))
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.register(UINib(nibName: "CollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "CollectionViewCell")
        diffableDataSource = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>(collectionView: collectionView) { [weak self] (collection, indexPath, _) -> UICollectionViewCell? in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as? CollectionViewCell , let section = self?.diffableDataSource?.snapshot().sectionIdentifiers[safe: indexPath.section] else { return nil }
            switch section {
            case .first(let items):
                if let item = items[safe: indexPath.item] {
                    cell.setUp(text: item.text, thumbnailURL: item.thumbnailURL)
                }
            case .second(let item):
                cell.setUp(text: item.text, thumbnailURL: item.thumbnailURL)
            }
            return cell
        }
        Task {
            models = try await ViewModel().fetch()
        }
    }


}

