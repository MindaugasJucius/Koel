//
//  ViewController.swift
//  Koel
//
//  Created by Mindaugas Jucius on 10/12/17.
//  Copyright © 2017 Mindaugas Jucius. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let modelManager = DMEventManager()
    
    let urlSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modelManager.createEvent()
        
        getWeatherData()
    }
    
    func getWeatherData() {
        //key - https://home.openweathermap.org/api_keys
        //api call - https://openweathermap.org/current
        //where to use api key - https://openweathermap.org/appid
        let vilniusWeatherUrl = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=vilnius&APPID=5a153f9ba6a63b4b39ec55c3e19af847")
        
        
        guard let url = vilniusWeatherUrl else {
            return
        }
        
        dataTask = urlSession.dataTask(
            with: url,
            completionHandler: { data, response, error in
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                if let data = data,
                    let response = response as? HTTPURLResponse,
                    response.statusCode == 200 {
                    print(data)
                    
                    let anyJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    guard let jsonDict = anyJson as? Dictionary<String, Any> else {
                        return
                    }
                    print(jsonDict.description)
                }
            }
        )
        
        dataTask?.resume()
    }
}
