//
//  INVVideoMetaExtension.swift
//
//  Created by Krzysztof Kryniecki on 9/29/16.
//  Copyright © 2016 InventiApps. All rights reserved.
//
import UIKit
import AVFoundation

extension INVVideoViewController:AVCaptureMetadataOutputObjectsDelegate {
    
    
    func printFaceLayer(layer: CALayer, faceObjects: [AVMetadataFaceObject])
    {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        // hide all the face layers
        var faceLayers = [CALayer]()
        for layer: CALayer in layer.sublayers!
        {
            if layer.name == "face" || layer.name == "body" || layer.name == "prop"
            {
                faceLayers.append(layer)
            }
        }
        for faceLayer in faceLayers
        {
            faceLayer.removeFromSuperlayer()
        }
        for faceObject in faceObjects {
            let careerHeadLayer = CALayer()
            let careerBodyLayer = CALayer()
            let careerHead = UIImage(named: (nc?.getHeadImage())!)?.cgImage
            let careerBody = UIImage(named: (nc?.getBodyImage())!)?.cgImage
            let faceScale = CGFloat((careerHead?.width)!)/faceObject.bounds.width
            let imageScale = CGFloat(1.3)
            let imageHeight = CGFloat((careerHead?.height)!)/faceScale*imageScale
            let imageWidth = faceObject.bounds.width*imageScale
            let eyeLevel = faceObject.bounds.minY+faceObject.bounds.height/3
            
            let headOverlayBounds = CGRect(
                x:faceObject.bounds.minX+faceObject.bounds.width/2-imageWidth/2,
                y:eyeLevel-imageHeight/2,
                width:imageWidth,
                height:imageHeight
            )
            
            let bodyScale = CGFloat(3)
            
            let bodyOverlayBounds = CGRect(
                x:faceObject.bounds.minX-faceObject.bounds.width,
                y:faceObject.bounds.maxY,
                width: bodyScale*faceObject.bounds.width,
                height: CGFloat((careerBody?.height)!)/(CGFloat((careerBody?.width)!)/(faceObject.bounds.width*bodyScale))
            )
            
            
            
            //Head Overlay
            careerHeadLayer.contents = careerHead
            careerHeadLayer.frame = headOverlayBounds
            //careerHeadLayer.borderColor = UIColor.green.cgColor
            //careerHeadLayer.borderWidth = 1.0
            careerHeadLayer.name = "face"
            
            //Body Overlay
            careerBodyLayer.contents = careerBody
            careerBodyLayer.frame = bodyOverlayBounds
            //careerBodyLayer.borderColor = UIColor.red.cgColor
            //careerBodyLayer.borderWidth = 1.0
            careerBodyLayer.name = "body"
            
            layer.addSublayer(careerBodyLayer)
            layer.addSublayer(careerHeadLayer)
            
            //Prop Overlay
            if(!(nc?.getPropImage().isEmpty)!)
            {
                let careerPropLayer = CALayer()
                let careerProp = UIImage(named: (nc?.getPropImage())!)?.cgImage
                let propOverlayBounds = CGRect(
                    x:0,
                    y:(Int(self.view.frame.size.height)-167-(careerProp?.height)!/5),
                    width:(careerProp?.width)!/5,
                    height:(careerProp?.height)!/5
                )
                careerPropLayer.contents = careerProp
                careerPropLayer.frame = propOverlayBounds
                careerPropLayer .name = "prop"
                layer.addSublayer(careerPropLayer)
            }
        }
        CATransaction.commit() 
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputMetadataObjects metadataObjects: [Any]!,
                       from connection: AVCaptureConnection!) {
        var faceObjects = [AVMetadataFaceObject]()
        for metadataObject in metadataObjects {
            if let metaFaceObject = metadataObject as? AVMetadataFaceObject,
                metaFaceObject.type == AVMetadataObjectTypeFace {
                if let object = self.previewLayer?.transformedMetadataObject(
                    for: metaFaceObject) as? AVMetadataFaceObject {
                    faceObjects.append(object)
                }
            }
        }
        if faceObjects.count >= 0, let layer = self.previewLayer {
            self.printFaceLayer(layer: layer, faceObjects: faceObjects)
        }
    }
    
    func debugFaceTracking()
    {
        
    }
}
