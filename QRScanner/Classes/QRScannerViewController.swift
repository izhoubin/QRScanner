//
//  QRScannerViewController.swift
//  QRScanner
//
//  Created by 周斌 on 2018/11/29.
//
import UIKit
import Foundation
import AVFoundation
public protocol QRScannerDelegate {
    func qrScannerDidFail(scanner:QRScannerViewController, error:Error)
    func qrScannerDidSuccess(scanner:QRScannerViewController, result:String)
}

public class QRScannerViewController: UIViewController {
    var cameraPreview: UIView = UIView()
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    public var delegate: QRScannerDelegate?
    let squareView = SquareView()
    let maskLayer = CAShapeLayer()
    let width:CGFloat = 250
    let scanLine = UIImageView()
    let torchItem = UIButton()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
        setUpLayout()
        setUpLayers()
    }
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        startScan()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer?.frame = cameraPreview.bounds
        maskLayer.frame = view.bounds
        let path = UIBezierPath(rect: squareView.frame)
        path.append(UIBezierPath(rect: view.bounds))
        maskLayer.path = path.cgPath
    }
    func setUpLayout(){
        guard let path = Bundle.main.path(forResource: "QRScanner", ofType: "framework", inDirectory: "Frameworks"), let framework = Bundle(path: path),let bundlePath = framework.path(forResource: "QRScanner", ofType: "bundle"),let bundle = Bundle(path: bundlePath) else{
            return
        }
        
        view.addSubview(cameraPreview)
        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        cameraPreview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        cameraPreview.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cameraPreview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(squareView)
        squareView.translatesAutoresizingMaskIntoConstraints = false
        squareView.widthAnchor.constraint(equalToConstant: width).isActive = true
        squareView.heightAnchor.constraint(equalToConstant: width).isActive = true
        squareView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        squareView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        squareView.addSubview(scanLine)
        scanLine.image = UIImage(named: "QRCode-line", in: bundle, compatibleWith: nil)
        scanLine.translatesAutoresizingMaskIntoConstraints = false
        scanLine.topAnchor.constraint(equalTo: squareView.topAnchor).isActive = true
        scanLine.heightAnchor.constraint(equalToConstant: 2).isActive = true
        scanLine.leftAnchor.constraint(equalTo: squareView.leftAnchor).isActive = true
        scanLine.rightAnchor.constraint(equalTo: squareView.rightAnchor).isActive = true
        
        view.addSubview(torchItem)
        torchItem.setImage(UIImage(named: "Torch-off", in: bundle, compatibleWith: nil), for: UIControl.State.normal)
        torchItem.setImage(UIImage(named: "Torch-on", in: bundle, compatibleWith: nil), for: UIControl.State.selected)
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
    
    func playAlertSound()
    {
        guard let path = Bundle.main.path(forResource: "QRScanner", ofType: "framework", inDirectory: "Frameworks"), let framework = Bundle(path: path),let bundlePath = framework.path(forResource: "QRScanner", ofType: "bundle"),let bundle = Bundle(path: bundlePath) else{
            return
        }
        guard let soundPath = bundle.path(forResource: "noticeMusic.caf", ofType: nil)  else { return }
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
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        }
        
        let metaOutput = AVCaptureMetadataOutput()
        
        if captureSession!.canAddOutput(metaOutput) {
            captureSession?.addOutput(metaOutput)
            metaOutput.metadataObjectTypes = metaOutput.availableMetadataObjectTypes
            metaOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: {[weak self] (noti) in
            guard let sf = self else{
                return
            }
            metaOutput.rectOfInterest = sf.previewLayer!.metadataOutputRectConverted(fromLayerRect: sf.squareView.frame)
        })
    }
    
    func startScan(){
        captureSession?.startRunning()
        startAnimation()
    }
    
    func stopScan(){
        captureSession?.stopRunning()
        stopAnimation()
    }
    
    private func startAnimation()
    {
        let startPoint = CGPoint(x: scanLine .center.x  , y: 1)
        let endPoint = CGPoint(x: scanLine.center.x, y: squareView.bounds.size.height - 2)
        
        let translation = CABasicAnimation(keyPath: "position")
        translation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        translation.fromValue = NSValue(cgPoint: startPoint)
        translation.toValue = NSValue(cgPoint: endPoint)
        translation.duration = 1
        translation.repeatCount = MAXFLOAT
        translation.autoreverses = true
        scanLine.layer.add(translation, forKey: "scan")
    }
    
    private func stopAnimation(){
        scanLine.layer.removeAllAnimations()
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QRScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let metadataDict = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        
        if let metadata = metadataDict as? [AnyHashable: Any],let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? [AnyHashable: Any],let brightness = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber {
            // 亮度值
            let brightnessValue = brightness.floatValue
            if let device = AVCaptureDevice.default(for: AVMediaType.video),device.hasTorch{
                if torchItem.isSelected == true{
                    torchItem.isHidden = false
                }else{
                    torchItem.isHidden = brightnessValue > 0
                }
            }
            
        }
    }
}
extension QRScannerViewController:AVCaptureMetadataOutputObjectsDelegate{
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for obj in metadataObjects{
            if let resultObj = obj as? AVMetadataMachineReadableCodeObject,let result = resultObj.stringValue{
                self.delegate?.qrScannerDidSuccess(scanner: self, result: result)
                playAlertSound()
                stopScan()
                break
            }
        }
        
    }
    
}

class SquareView: UIView {
    var sizeMultiplier : CGFloat = 0.1 {
        didSet{
            self.draw(self.bounds)
        }
    }
    
    var lineWidth : CGFloat = 2 {
        didSet{
            self.draw(self.bounds)
        }
    }
    var lineColor : UIColor = UIColor.green {
        didSet{
            self.draw(self.bounds)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
    func drawCorners() {
        let rectCornerContext = UIGraphicsGetCurrentContext()
        
        rectCornerContext?.setLineWidth(lineWidth)
        rectCornerContext?.setStrokeColor(lineColor.cgColor)
        
        //top left corner
        rectCornerContext?.beginPath()
        rectCornerContext?.move(to: CGPoint(x: 0, y: 0))
        rectCornerContext?.addLine(to: CGPoint(x: self.bounds.size.width*sizeMultiplier, y: 0))
        rectCornerContext?.strokePath()
        
        //top rigth corner
        rectCornerContext?.beginPath()
        rectCornerContext?.move(to: CGPoint(x: self.bounds.size.width - self.bounds.size.width*sizeMultiplier, y: 0))
        rectCornerContext?.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
        rectCornerContext?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height*sizeMultiplier))
        rectCornerContext?.strokePath()
        
        //bottom rigth corner
        rectCornerContext?.beginPath()
        rectCornerContext?.move(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height - self.bounds.size.height*sizeMultiplier))
        rectCornerContext?.addLine(to: CGPoint(x: self.bounds.size.width, y: self.bounds.size.height))
        rectCornerContext?.addLine(to: CGPoint(x: self.bounds.size.width - self.bounds.size.width*sizeMultiplier, y: self.bounds.size.height))
        rectCornerContext?.strokePath()
        
        //bottom left corner
        rectCornerContext?.beginPath()
        rectCornerContext?.move(to: CGPoint(x: self.bounds.size.width*sizeMultiplier, y: self.bounds.size.height))
        rectCornerContext?.addLine(to: CGPoint(x: 0, y: self.bounds.size.height))
        rectCornerContext?.addLine(to: CGPoint(x: 0, y: self.bounds.size.height - self.bounds.size.height*sizeMultiplier))
        rectCornerContext?.strokePath()
        
        //second part of top left corner
        rectCornerContext?.beginPath()
        rectCornerContext?.move(to: CGPoint(x: 0, y: self.bounds.size.height*sizeMultiplier))
        rectCornerContext?.addLine(to: CGPoint(x: 0, y: 0))
        rectCornerContext?.strokePath()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.drawCorners()
    }
    
}
