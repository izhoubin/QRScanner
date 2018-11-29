//
//  ViewController.swift
//  QRScanner
//
//  Created by izhoubin on 11/29/2018.
//  Copyright (c) 2018 izhoubin. All rights reserved.
//

import UIKit
import QRScanner
class ViewController: UIViewController{
    
    let qr = QRScannerViewController()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view, typically from a nib.
        qr.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        present(qr, animated: true, completion: nil)
    }
}
extension ViewController:QRScannerDelegate{
    func qrScannerDidFail(scanner: QRScannerViewController, error: Error) {
        print(error.localizedDescription)
    }
    
    func qrScannerDidSuccess(scanner: QRScannerViewController, result: String) {
        print(result)
    }
}

