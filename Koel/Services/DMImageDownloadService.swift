//
//  DMImageDownloadService.swift
//  Koel
//
//  Created by Mindaugas on 01/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import Foundation
import RxSwift

private let timeout: TimeInterval = 30

class DMImageDownloadService: NSObject {
    
    static func downloadImage(fromURL url: URL) -> Observable<UIImage?> {
        return URLSession.shared.rx
            .data(request: request(fromURL: url))
            .map { data -> UIImage? in
                return UIImage(data: data)
            }
            .catchErrorJustReturn(nil)
    }
    
    private static func request(fromURL url: URL) -> URLRequest {
        return URLRequest(url: url,
                          cachePolicy: .returnCacheDataElseLoad,
                          timeoutInterval: timeout)
    }
    
}

extension Observable where Element: Sequence, Element.Element: ImageContaining  {
    
    func downloadImages() -> Observable<[Element.Element]> {
        let downloadObservables = map { $0.map { Observable<Element.Element>.just($0).downloadImage() } }
        return downloadObservables
            .flatMap { downloadObservables in
                return Observable<Element.Element>.merge(downloadObservables)
            }
            .reduce([], accumulator: { (array, entity) in
                return array + [entity]
            })
            .debug("download image", trimOutput: true)
    }
    
}

extension Observable where Element: ImageContaining {
    
    func downloadImage() -> Observable<Element> {
        return self.flatMap { imageContaining -> Observable<Element> in 
            guard let imageURL = imageContaining.imageURL else {
                return .just(imageContaining)
            }
            
            return DMImageDownloadService.downloadImage(fromURL: imageURL)
                .map { maybeImage -> Element in
                    guard let image = maybeImage else {
                        return imageContaining
                    }
                    var imageContaining = imageContaining
                    imageContaining.image = image
                    return imageContaining
                }
        }
    }
    
}
