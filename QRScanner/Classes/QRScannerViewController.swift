//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by 周斌 on 2018/11/29.
//
import UIKit
import Foundation
import AVFoundation
public protocol QRScannerDelegate:class {
    func qrScannerDidFail(scanner:QRScannerViewController, error:Error)
    func qrScannerDidSuccess(scanner:QRScannerViewController, result:String)
}

public class QRScannerViewController: UIViewController {
    
    let cameraPreview: UIView = UIView()
    let squareView = QRScannerSquareView()
    let maskLayer = CAShapeLayer()
    let torchItem = UIButton()
    let metaDataQueue = DispatchQueue(label: "metaDataQueue")
    let videoQueue = DispatchQueue(label: "videoQueue")
    
    public weak var delegate: QRScannerDelegate?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    lazy var resourcesBundle:Bundle? = {
        if let path = Bundle.main.path(forResource: "QRScanner", ofType: "framework", inDirectory: "Frameworks"),
        let framework = Bundle(path: path),
        let bundlePath = framework.path(forResource: "QRScanner", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath){
            return bundle
        }
        return nil
    }()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
        checkPermissions()
        setUpLayout()
        setUpLayers()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        squareView.startAnimation()
    }
    
    func checkPermissions(){
        QRScannerPermissions.authorizeCameraWith {[weak self] in
            if $0{ self?.captureSession?.startRunning()}
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = cameraPreview.bounds
        maskLayer.frame = view.bounds
        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(rect: squareView.frame))
        maskLayer.path = path.cgPath
    }
    
    func setUpLayout(){
        view.backgroundColor = UIColor.clear
        view.addSubview(cameraPreview)
        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cameraPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let length = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 100
        view.addSubview(squareView)
        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.widthAnchor.constraint(equalToConstant: length).isActive = true
        squareView.heightAnchor.constraint(equalToConstant: length).isActive = true
        squareView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        squareView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(torchItem)
        torchItem.setImage(UIImage(named: "Torch-off", in: resourcesBundle, compatibleWith: nil), for: UIControl.State.normal)
        torchItem.setImage(UIImage(named: "Torch-on", in: resourcesBundle, compatibleWith: nil), for: UIControl.State.selected)
        torchItem.addTarget(self, action: #selector(toggleTorch), for: UIControl.Event.touchUpInside)
        torchItem.isHidden = true
        torchItem.translatesAutoresizingMaskIntoConstraints = false
        torchItem.topAnchor.constraint(equalTo: squareView.bottomAnchor, constant: 30).isActive = true
        torchItem.heightAnchor.constraint(equalToConstant: 30).isActive = true
        torchItem.widthAnchor.constraint(equalToConstant: 30).isActive = true
        torchItem.centerXAnchor.constraint(equalTo: squareView.centerXAnchor).isActive = true
    }
    
    @objc func toggleTorch(bt:UIButton){
        bt.isSelected = !bt.isSelected
        guard let device = AVCaptureDevice.default(for: AVMediaType.video)else{return}
        try? device.lockForConfiguration()
        device.torchMode = bt.isSelected ? .on : .off
        device.unlockForConfiguration()
    }
    
    func setUpLayers(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        let viewLayer = cameraPreview.layer
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        viewLayer.addSublayer(previewLayer!)
        
        maskLayer.fillColor = UIColor(white: 0.0, alpha: 0.5).cgColor
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        view.layer.insertSublayer(maskLayer, above: previewLayer)
    }
    
    func playAlertSound(){
        guard let soundPath = resourcesBundle?.path(forResource: "noticeMusic.caf", ofType: nil)  else { return }
        guard let soundUrl = NSURL(string: soundPath) else { return }
        
        var soundID:SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundUrl, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }
    
    func setupCameraSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSession.Preset.high
        do {
            let device = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: device!)
            captureSession?.addInput(input)
        } catch {
            self.delegate?.qrScannerDidFail(scanner: self, error: error)
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        if captureSession!.canAddOutput(videoOutput) {
            captureSession?.addOutput(videoOutput)
            
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        }
        
        let metaOutput = AVCaptureMetadataOutput()
        
        if captureSession!.canAddOutput(metaOutput) {
            captureSession?.addOutput(metaOutput)
            metaOutput.metadataObjectTypes = metaOutput.availableMetadataObjectTypes
            metaOutput.setMetadataObjectsDelegate(self, queue: metaDataQueue)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: {[weak self] (noti) in
            guard let sf = self else{
                return
            }
            metaOutput.rectOfInterest = sf.previewLayer!.metadataOutputRectConverted(fromLayerRect: sf.squareView.frame)
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QRScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        videoQueue.async {[weak self] in
            guard let sf = self else{return}
            let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
            if let metadata = metadataDict as? [AnyHashable: Any],let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? [AnyHashable: Any],let brightness = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber {
                if let device = AVCaptureDevice.default(for: AVMediaType.video),device.hasTorch{
                    DispatchQueue.main.async {
                        if sf.torchItem.isSelected == true{
                            sf.torchItem.isHidden = false
                        }else{
                            sf.torchItem.isHidden = brightness.floatValue > 0
                        }
                    }
                }
            }
        }
    }
}

extension QRScannerViewController:AVCaptureMetadataOutputObjectsDelegate{
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        metaDataQueue.async {[weak self] in
            guard let sf = self else{return}
            for obj in metadataObjects{
                if let resultObj = obj as? AVMetadataMachineReadableCodeObject,let result = resultObj.stringValue{
                    DispatchQueue.main.async {
                        sf.delegate?.qrScannerDidSuccess(scanner: sf, result: result)
                        sf.playAlertSound()
                        sf.captureSession?.stopRunning()
                        sf.squareView.stopAnimation()
                    }
                    break
                }
            }
        }
    }
}
