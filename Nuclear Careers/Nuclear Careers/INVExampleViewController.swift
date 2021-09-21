//
//  INVExampleViewController.swift
//  FaceDetection
//
//  Created by Krzysztof Kryniecki on 2/17/17.
//  Copyright © 2017 InventiApps. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI
final class INVExampleViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate
{
    
    private var videoComponent: INVVideoComponent?
    var nc = NuclearCareer()
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var careerPicker: UIPickerView!
    @IBOutlet weak var backgroundUpper: UITextView!
    @IBOutlet weak var backgroundLower: UITextView!
    weak var combinedPicture: UIImage!
    @IBOutlet weak var careerText: UILabel!
    
    //use this to set kioskMode
    // Kiosk Mode automatically opens up email client for sharing
    // When false it opens up regular sharing features
    static var KioskMode = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        careerPicker.delegate = self
        careerPicker.dataSource = self
        
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        var selection = careerPicker.selectedRow(inComponent: 0)
        nc.update(newID: selection)
        self.videoComponent = INVVideoComponent(
            atViewController: self,
            cameraType: .front,
            withAccess: .video,
            career: nc
        )
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        print("DEBUG Starting Live Preview")
        self.videoComponent?.startLivePreview()
        
        self.manageSubviews()
    }
    override func viewDidDisappear(_ animated: Bool)
    {
        print("DEBUG Starting Live Preview")
        super.viewDidDisappear(animated)
        self.videoComponent?.stopLivePreview()
    }
    
    func manageSubviews()
    {
        view.bringSubview(toFront: backgroundUpper)
        view.bringSubview(toFront: backgroundLower)
        view.bringSubview(toFront: cameraButton)
        view.bringSubview(toFront: careerText)
        view.bringSubview(toFront: careerPicker)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return nc.names.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return nc.names[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        nc.update(newID: row)
        careerText.text = nc.getDescription()
        //print("First \(nc.getID()),Second \(videoComponent?.nc.getID() ?? -1), Third \(videoComponent?.getVideoController().nc?.getID() ?? -1)")
        
    }
    func getCareerObject()->NuclearCareer
    {
        return nc
    }
    @IBAction func buttonPressed(_ sender: Any)
    {
        if (AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == AVAuthorizationStatus.authorized)
        {
            takePicture()
        }
        else
        {
            alert(message: "Camera permissions need to be enabled before this app can be used.")
        }
    }
    
    func takePicture()
    {
        shutterFlash()
        //videoComponent!.getVideoController().saveToCamera() test photo image, used for testing
        videoComponent!.getVideoController().capturePhotoOutput
            { (image) in
                
                guard let photoImage2 = image else
                {
                    print("DEBUG ERROR No image")
                    return
                }
                let photoImage = UIImage(cgImage: photoImage2.cgImage!, scale: CGFloat(1.0), orientation: UIImageOrientation.leftMirrored)
                let overlayImage = self.videoComponent!.getVideoController().captureOverlayView()
                print("DEBUG Photo Width: ",photoImage.size.width," Height: ",photoImage.size.height)
                print("DEBUG Overlay Width: ",overlayImage.size.width," Height: ",overlayImage.size.height)
                let textImage = self.captureTextView() //text
                let testWidth = textImage.size.width+32
                
                let overlayHeight = overlayImage.size.height*testWidth/overlayImage.size.width
                let photoHeight = photoImage.size.height*testWidth/photoImage.size.width
                
                //adjusting original image
                let heightDiff = photoHeight-overlayHeight

                var size = CGSize()
                if(heightDiff > 0)
                {
                    size = CGSize(width:testWidth,height:overlayHeight+textImage.size.height)

                }
                else
                {
                    size = CGSize(width:testWidth,height:photoHeight+textImage.size.height)
                }

        
                
                let rectangle = CGRect(x: 0, y: size.height - textImage.size.height, width: size.width, height: textImage.size.height)

                //testing for fiing ipad / iphone x picture bugs
                
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                let context = UIGraphicsGetCurrentContext()
                context?.setFillColor(UIColor.gray.cgColor)
                
                if(heightDiff > 0)
                {
                    photoImage.draw(in: CGRect(x:0, y:0-(heightDiff/2), width:size.width, height: photoHeight))
                    overlayImage.draw(in: CGRect(x:0,y:0,width: size.width, height: overlayHeight))
                    
                }
                else
                {
                    photoImage.draw(in: CGRect(x:0, y:0, width:size.width, height: photoHeight))
                    overlayImage.draw(in: CGRect(x:0,y:0+(heightDiff/2),width: size.width, height: overlayHeight))

                }
                
                context?.addRect(rectangle)
                context?.drawPath(using: .fill)
                
                textImage.draw(in: CGRect(x:16, y:size.height - textImage.size.height, width: textImage.size.width, height: textImage.size.height))
                
                let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                UIGraphicsEndImageContext()
                self.shareIMG(image: newImage,kioskMode: INVExampleViewController.KioskMode)
        }
    }
    
    func shutterFlash()
    {
        let shutterView = UIView(frame: videoComponent!.getVideoController().view.frame)
        shutterView.backgroundColor = UIColor.white
        view.addSubview(shutterView)
        UIView.animate(withDuration: 0.3, animations: {
            shutterView.alpha = 0
        }, completion: { (_) in
            shutterView.removeFromSuperview()
        })
    }
    
    func captureTextView()->UIImage
    {
        UIGraphicsBeginImageContext(careerText.bounds.size)
        careerText.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func shareIMG(image:UIImage,kioskMode:Bool)
    {
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil)
        let messageStr = "I am the #FutureOfEnergy"
        //let activityItems = [image,messageStr] as [Any]
        if(kioskMode)
        {
                if MFMailComposeViewController.canSendMail()
                {
                    let mail = MFMailComposeViewController()
                    mail.mailComposeDelegate = self;
                    //mail.setCcRecipients(["yyyy@xxx.com"])
                    mail.setSubject("Nuclear Careers")
                    mail.setMessageBody(messageStr, isHTML: false)
                    let imageData: NSData = UIImagePNGRepresentation(image)! as NSData
                    mail.addAttachmentData(imageData as Data, mimeType: "image/png", fileName: "imageName")
                    self.present(mail, animated: true, completion: nil)
                }
                else
                {
                    // add alert to tell user to set up an email account on device
                }
        }
        else
        {
            let avc = UIActivityViewController(activityItems: [image,messageStr], applicationActivities: nil)
            if(UIDevice.current.userInterfaceIdiom == .pad)
            {
                if ( avc.responds(to:#selector(getter: UIViewController.popoverPresentationController)) ) {
                    avc.popoverPresentationController?.sourceView = super.view
                }
            }
            self.present(avc, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        switch result
        {
        case .cancelled:
            break
        case .saved:
            break
        case .sent:
            break
        case .failed:
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func alert(message: String, title: String = "")
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }

    
}
