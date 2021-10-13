//
//  ViewController.swift
//  BitcoinPriceChecker
//
//  Created by Kotaro Suto on 2019/01/15.
//  Copyright © 2019年 Kotaro Suto. All rights reserved.
//

import UIKit
import Alamofire
import Combine

class ViewController: UIViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var curPriceLabel: UILabel!
    @IBOutlet weak var detailsTextView: UITextView!
    
    @Published var priceListStr: String = ""
    @Published var currentPriceStr: String = ""
    @Published var priceArray: [Int] = []
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = "No Data"
        
        $priceArray
            .filter {
                $0.count >= 2
            }
            .map { arr in
                if arr.reversed().first! > arr.reversed()[1] {
                    return "Up"
                } else if arr.reversed().first! < arr.reversed()[1] {
                    return "Down"
                } else {
                    return "Same Price"
                }
            }
            .assign(to: \.text, on: statusLabel)
            .store(in: &cancellables)
        
        $priceListStr
            .assign(to: \.text, on: detailsTextView)
            .store(in: &cancellables)
        
        $currentPriceStr
            .sink { str in
                self.curPriceLabel.text = str
            }
            .store(in: &cancellables)
        
        getPrice()
    }
    
    func getPrice() {
        AF.request("https://api.bitflyer.com/v1/getboard").responseData { response in
            if case .success(let json) = response.result {
                do {
                    let decoder = JSONDecoder()
                    let boardInfo = try decoder.decode(BoardInfo.self, from: json)
                    self.priceArray.append(boardInfo.mid_price)
                    self.currentPriceStr = "\(self.getDateStr()): ¥\(boardInfo.mid_price)"
                    self.priceListStr = "\(self.getDateStr()): ¥\(boardInfo.mid_price)\n" + self.priceListStr
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
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        let now = Date()
        return formatter.string(from: now)
    }
    
    
}

struct BoardInfo: Codable {
    // swiftlint: disable identifier_name
    var mid_price: Int
}

