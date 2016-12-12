//
//  ViewController.swift
//  MovieNight
//
//  Created by Katherine Ebel on 12/9/16.
//  Copyright © 2016 Katherine Ebel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    if let api_key = appDelegate.keys.api_key() {
      let urlString = "https://api.themoviedb.org/3/person/popular?api_key=\(api_key)&language=en-US"
      let url = URL(string: urlString)!
      let request = URLRequest(url: url)
      let session = URLSession.shared
      let task = session.dataTask(with: request) { data, response, error in
        guard let HTTPResponse = response as? HTTPURLResponse else {
          print("Error: \(error)")
          return
        }
        print(HTTPResponse.statusCode)
        if let data = data {
          do {
            let responseDict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            if let responseDict = responseDict as? [String: Any] {
              if let results = responseDict["results"] as? [[String: Any]] {
                print("Num results: \(results.count)")
              }
            }
          } catch let error {
            print(error.localizedDescription)
          }
        }
    }
    task.resume()
      
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

