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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    @IBAction func startScan(_ sender: Any) {
        let qr = QRScannerViewController()
        qr.delegate = self
        navigationController?.pushViewController(qr, animated: true)
    }
}
extension ViewController:QRScannerDelegate{
    func qrScannerDidFail(scanner: QRScannerViewController, error: Error) {
        let alert = UIAlertController(title: "Fail!", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
    
    func qrScannerDidSuccess(scanner: QRScannerViewController, result: String) {
        let alert = UIAlertController(title: "Success!", message: result, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
}

