//
//  ViewController.swift
//  QRScanner
//
//  Created by izhoubin on 11/29/2018.
//  Copyright (c) 2018 izhoubin. All rights reserved.
//

import UIKit
import QRScanner
class ViewController: UITableViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
extension ViewController:QRScannerDelegate{
    func qrScannerDidFail(scanner: QRScannerViewController, error: QRScannerError) {
        let alert = UIAlertController(title: "Fail!", message: String(describing: error), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
    
    func qrScannerDidSuccess(scanner: QRScannerViewController, result: String) {
        print("success",result)
        let alert = UIAlertController(title: "Success!", message: result, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: nil))
        scanner.present(alert, animated: true, completion: nil)
    }
}


extension ViewController{
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let qr = QRScannerViewController()
        qr.squareView.lineColor = UIColor.red
        let item = UIBarButtonItem(title: "Photo album", style: UIBarButtonItem.Style.plain, target: qr, action: #selector(QRScannerViewController.openAlbum))
        qr.navigationItem.rightBarButtonItem = item
        qr.delegate = self
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(qr, animated: true)
        case 1:
            present(qr, animated: true, completion: nil)
        default:
            break
        }
    }
}
