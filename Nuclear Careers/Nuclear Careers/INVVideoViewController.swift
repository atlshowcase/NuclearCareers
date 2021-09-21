//
//  INVVideoViewController.swift
//
//
//  Created by Krzysztof Kryniecki on 9/23/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import CoreImage
import ImageIO
import CoreFoundation

enum INVVideoControllerErrors: Error {
    case unsupportedDevice
    case videoNotConfigured
    case undefinedError
}
enum INVVideoAccessType {
    case video
    case unknown
}

class INVVideoViewController: UIViewController {
    var errorBlock: ((_ error: Error) -> Void)?
    var componentReadyBlock: (() -> Void)?
    private enum INVVideoQueuesType: String {
        case session
        case camera
    }
    
    
    public var nc:NuclearCareer?
    //var cameraImage: UIImage?
    
    private var currentAccessType: INVVideoAccessType = .unknown
    var captureOutput: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var stillImageOutput : AVCaptureStillImageOutput?
    
    let newPreviewBounds = CGRect(
        x:0,
        y:0,
        width:UIScreen.main.bounds.width,
        height:UIScreen.main.bounds.height
    )
    
    fileprivate let sessionQueue = DispatchQueue(
        label: INVVideoQueuesType.session.rawValue,
        qos: .userInteractive,
        target: nil
    )
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var runtimeCaptureErrorObserver: NSObjectProtocol?
    fileprivate var movieFileOutputCapture: AVCaptureMovieFileOutput?
    fileprivate let kINVRecordedFileName = "movie.mov"
    private var isAssetWriter: Bool = false
    
    
    private func deviceWithMediaType(
        mediaType: String,
        position: AVCaptureDevicePosition?) throws -> AVCaptureDevice? {

        if let devices = AVCaptureDevice.devices(withMediaType: mediaType),
            let devicePosition = position {
            for deviceObj in devices {
                if let device = deviceObj as? AVCaptureDevice,
                    device.position == devicePosition {
                    return device
                }
            }
        } else {
            if let devices = AVCaptureDevice.devices(withMediaType: mediaType),
                let device = devices.first as? AVCaptureDevice {
                return device
            }
        }
        throw INVVideoControllerErrors.unsupportedDevice
    }

    private func setupPreviewView(session: AVCaptureSession) throws {
        if let previewLayer = AVCaptureVideoPreviewLayer(session: session) {
            previewLayer.masksToBounds = true
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill

            
            //Use AVLayerVideoGravityResizeAspect or AVLayerVideoGravityResizeAspectFill
            self.view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
            
            //print("M DEBUG Preview bounds:", self.view.frame.width, " Height:", self.view.frame.height)
            self.previewLayer?.frame = newPreviewBounds
        } else {
            print("DEBUG setupPreviewView error")
            throw INVVideoControllerErrors.undefinedError
        }
    }

    private func setupCaptureSession(cameraType: AVCaptureDevicePosition) throws {
        let videoDevice = try self.deviceWithMediaType(
            mediaType: AVMediaTypeVideo,
            position: cameraType
        )
        let captureDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        if self.captureSession.canAddInput(captureDeviceInput) {
            self.captureSession.addInput(captureDeviceInput)
        } else {
            errorBlock?(INVVideoControllerErrors.unsupportedDevice)
        }
    }

    private func handleVideoRotation()
    {
        if let connection =  self.previewLayer?.connection
        {
            let orientation: UIDeviceOrientation = .portrait
            let previewLayerConnection: AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported,
                let videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)
            {
                previewLayer?.connection.videoOrientation = videoOrientation
            }
            if let outputLayerConnection: AVCaptureConnection = self.captureOutput?.connection(
                withMediaType: AVMediaTypeVideo)
            {
                if outputLayerConnection.isVideoOrientationSupported,
                    let videoOrientation = AVCaptureVideoOrientation(rawValue:
                        orientation.rawValue)
                {
                    outputLayerConnection.videoOrientation = videoOrientation
                    outputLayerConnection.isVideoMirrored = true
                }
            }
        }
    }

    private func requestVideoAccess(requestedAccess: INVVideoAccessType)
    {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (isGranted) in
            if isGranted
            {
                switch self.currentAccessType {
                case .unknown:
                    self.currentAccessType = .video
                default:
                    break
                }
            }
            if self.currentAccessType == requestedAccess {
                DispatchQueue.main.async {
                    self.componentReadyBlock?()
                }
            }
        })
    }


    func setupDeviceCapture(requiredAccessType: INVVideoAccessType) {
        if self.currentAccessType != requiredAccessType {
            switch requiredAccessType {
            case .video:
                self.requestVideoAccess(requestedAccess: requiredAccessType)
                break
            case .unknown:
                self.errorBlock?(INVVideoControllerErrors.videoNotConfigured)
                break
            }
        } else {
            DispatchQueue.main.async {
                self.componentReadyBlock?()
            }
        }
    }
    // Sets Up Capturing Devices
    func configureDeviceCapture(cameraType: AVCaptureDevicePosition) {
        do {
            try self.setupPreviewView(session: self.captureSession)
        } catch {
            print("DEBUG configureDeviceCapture error")
            errorBlock?(INVVideoControllerErrors.undefinedError)
        }
        do {
            try self.setupCaptureSession(cameraType: cameraType)
        } catch INVVideoControllerErrors.unsupportedDevice {
            errorBlock?(INVVideoControllerErrors.unsupportedDevice)
        } catch {
            print("DEBUG configureDeviceCapture error")
            errorBlock?(INVVideoControllerErrors.undefinedError)
        }
    }

}

extension INVVideoViewController {
    func startCaptureSession() {
        self.captureSession.startRunning()
        
        self.previewLayer?.connection.automaticallyAdjustsVideoMirroring = false
        self.previewLayer?.connection.isVideoMirrored = true
        self.runtimeCaptureErrorObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.AVCaptureSessionRuntimeError,
            object: self.captureSession,
            queue: nil
        ) { [weak self] _ in
            self?.errorBlock?(INVVideoControllerErrors.undefinedError)
            print("DEBUG startCaptureSession error")
        }
    }

    func stopCaptureSession() {
        self.captureSession.stopRunning()
        if let observer = self.runtimeCaptureErrorObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func startMetaSession()
    {
        let metadataOutput = AVCaptureMetadataOutput()
        metadataOutput.setMetadataObjectsDelegate(self, queue: self.sessionQueue)
        if self.captureSession.canAddOutput(metadataOutput)
        {
            self.captureSession.addOutput(metadataOutput)
        }
        
        if metadataOutput.availableMetadataObjectTypes.contains(where: { (type) -> Bool in
                if let metaType = type as? String {
                    return metaType == AVMetadataObjectTypeFace
                }
                return false
            }) {
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        } else {
            print("DEBUG startMetaSession error")
           self.errorBlock?(INVVideoControllerErrors.undefinedError)
        }
    }
    func startPictureSession()
    {
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.accessibilityFrame = newPreviewBounds
        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if self.captureSession.canAddOutput(stillImageOutput) {
            //print("M DEBUG AVCaptureStillImageOutput added")
            self.captureSession.addOutput(stillImageOutput)
        }
    }
    
    public func captureOverlayView()->UIImage
    {

        UIGraphicsBeginImageContextWithOptions(newPreviewBounds.size,false,0.0)
        self.view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public func capturePhotoOutput(completion: @escaping (UIImage?)->())
    {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)
        {
            //print("M DEBUG Video Connection established")
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil)
                {
                    //print("M DEBUG Sample Buffer not nil")
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData! as CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
                    let camImage = UIImage(cgImage: cgImageRef!, scale: CGFloat(1.0), orientation: UIImageOrientation.right)
                    
                    completion(camImage)
                }
                else
                {
                    completion(nil)
                }
            })
            
        }
        else
        {
            completion(nil)
        }
    }
    
    public func saveToCamera() {
        
        if let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (CMSampleBuffer, Error) in
                
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(CMSampleBuffer)
                {
                    if let cameraImage = UIImage(data: imageData)
                    {
                            UIImageWriteToSavedPhotosAlbum(cameraImage, nil, nil, nil)
                    }
                }
            })
        }
    }

}
