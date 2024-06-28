//
//  ViewController.swift
//  BitcoinPriceChecker
//
//  Created by Kotaro Suto on 2019/01/15.
//  Copyright © 2019年 Kotaro Suto. All rights reserved.
//

import UIKit
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
        let bitflyerAPI = URL(string: "https://api.bitflyer.com/")!
        let task =
        URLSession.shared.dataTask(with: bitflyerAPI.appending(components: "v1","getboard")) { data, res, err in
            if let err {
                print("Failed with \(err)")
                return
            }
            guard let data, let res else { return }
            let decoder = JSONDecoder()
            let boardInfo = try! decoder.decode(BoardInfo.self, from: data)
            DispatchQueue.main.sync {
                self.priceArray.append(boardInfo.mid_price)
                self.currentPriceStr = "\(self.getDateStr()): ¥\(boardInfo.mid_price)"
                self.priceListStr = "\(self.getDateStr()): ¥\(boardInfo.mid_price)\n" + self.priceListStr
            }
        }
        task.resume()
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
    // swiftlint:disable identifier_name
    var mid_price: Int
}

