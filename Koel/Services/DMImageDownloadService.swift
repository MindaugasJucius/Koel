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
    
    func downloadImage(fromURL url: URL) -> Observable<UIImage?> {
        return URLSession.shared.rx
            .data(request: request(fromURL: url))
            .map { data -> UIImage? in
                return UIImage(data: data)
            }
            .catchErrorJustReturn(nil)
    }
    
    private func request(fromURL url: URL) -> URLRequest {
        return URLRequest(url: url,
                          cachePolicy: .returnCacheDataElseLoad,
                          timeoutInterval: timeout)
    }
    
}
