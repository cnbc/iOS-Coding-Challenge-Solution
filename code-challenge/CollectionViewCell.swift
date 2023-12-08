//
//  CollectionViewCell.swift
//  code-challenge
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = nil
        imageView.image = nil
    }

    func setUp(text: String, thumbnailURL: String?) {
        label.text = text
        if let thumbnailURL, let url = URL(string: thumbnailURL) {
            NetworkRequestManager().fetch(from: url) { data, response, _ in
                if let data, url.absoluteString == (response?.url?.absoluteString ?? "!@#") {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }
    }
}
