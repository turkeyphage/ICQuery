//
//  UIImageView+DownloadImage.swift
//  ICQuery
//
//  Created by Roger on 2016/12/23.
//  Copyright © 2016年 ICQuery. All rights reserved.
//

import UIKit


extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        // 1
        let downloadTask = session.downloadTask(with: url, completionHandler: { [weak self] url, response, error in
            if error == nil, let url = url,
                let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            } else {
                print("Error: \(error)")
            }
        })
        
        downloadTask.resume()
        return downloadTask
    }
}
