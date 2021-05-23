//
//  ViewController.swift
//  BitcoinPriceChecker
//
//  Created by Kotaro Suto on 2019/01/15.
//  Copyright © 2019年 Kotaro Suto. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var curPriceLabel: UILabel!
    @IBOutlet weak var detailsTextView: UITextView!
 
    var priceListStr: BehaviorRelay<String>!
    var currentPriceStr: BehaviorRelay<String>!
    var priceArray: BehaviorRelay<[Int]>!
    let dispose = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        priceArray = BehaviorRelay(value: [])
        _ = priceArray
            .asObservable()
            .map { arr in
                print("arr:\(arr)")
                if arr.count > 1 {
                    if arr.reversed().first! > arr.reversed()[1] {
                        return "Up"
                    } else if arr.reversed().first! < arr.reversed()[1] {
                        return "Down"
                    } else if arr.reversed().first! == arr.reversed()[1] {
                        return "Same Price"
                    } else {
                        return "No Data"
                    }
                } else {
                    return "No Data"
                }
            }
            .bind(to: statusLabel.rx.text)
            .disposed(by: dispose)
        
      priceListStr = BehaviorRelay(value: "")
        _ = priceListStr
            .asObservable()
            .bind(to: detailsTextView.rx.text)
            .disposed(by: dispose)

      currentPriceStr = BehaviorRelay(value: "")
        _ = currentPriceStr
            .asObservable()
            .bind(to: curPriceLabel.rx.text)
            .disposed(by: dispose)
        
        getPrice()
    }
    
    func getPrice() {
        AF.request("https://api.bitflyer.com/v1/getboard").responseData { response in
          if case .success(let json) = response.result {
                print("JSON: \(json)")
                do {
                    let decoder = JSONDecoder()
                    let boardInfo = try decoder.decode(BoardInfo.self, from: json)
                    print("\(self.getDateStr()): ¥\(boardInfo.mid_price)")
                    var i = self.priceArray.value
                    i.append(boardInfo.mid_price)
                    self.priceArray.accept(i)
                    print(self.priceArray.value)
                    self.currentPriceStr.accept("\(self.getDateStr()): ¥\(boardInfo.mid_price)")
                    self.priceListStr.accept( "\(self.getDateStr()): ¥\(boardInfo.mid_price)\n" + self.priceListStr.value)
                } catch {
                    print("Failed")
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.getPrice()
        }
    }
    
    func getDateStr() -> String {
        let f = DateFormatter()
        f.timeStyle = .medium
        f.dateStyle = .medium
        f.locale = Locale(identifier: "ja_JP")
        let now = Date()
        return f.string(from: now)
    }
    
    
}

struct BoardInfo: Codable {
    var mid_price: Int
    
}

