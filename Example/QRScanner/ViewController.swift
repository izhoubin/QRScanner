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
    }
    @IBAction func startScan(_ sender: Any) {
        let qr = QRScannerViewController()
        qr.squareView.lineColor = UIColor.red
        let item = UIBarButtonItem(title: "相册", style: UIBarButtonItem.Style.plain, target: qr, action: #selector(QRScannerViewController.openAlbum))
        qr.navigationItem.rightBarButtonItem = item
        qr.delegate = self
        navigationController?.pushViewController(qr, animated: true)
    }
}
extension ViewController:QRScannerDelegate{
    func qrScannerDidFail(scanner: QRScannerViewController, error: QRScannerError) {
        let alert = UIAlertController(title: "Fail!", message: String(describing: error), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
    
    func qrScannerDidSuccess(scanner: QRScannerViewController, result: String) {
        let alert = UIAlertController(title: "Success!", message: result, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
}


