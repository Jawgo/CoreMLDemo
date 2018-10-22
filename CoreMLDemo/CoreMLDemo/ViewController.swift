//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Nicolette Mulyk on 2018-10-21.
//  Copyright © 2018 Joshua Schijns. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var scene: UIImageView!
    @IBOutlet weak var answerLabel: UILabel!
    
    // Initialize the UIImagePickerController
    let imageController = UIImagePickerController()
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        
        //fetch the image from the UIImagePicker
        guard let image = info[.originalImage] as? UIImage else {
            fatalError("Not able to load image from Photos")
        }
        
        scene.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Not able to convert UIImage to CIImage")
        }
        
        // method to detect the image and give the prediction
        detectScene(image: ciImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the mode for UIImagePickerController
        imageController.isEditing = false
        
        // set the delegate
        imageController.delegate = self;
        
        // set the default image
        guard let image = UIImage.init(named: "scene") else {
            fatalError("No default image found")
        }
        
        scene.image = image
        
        guard let ciImage = CIImage(image: image) else {
            fatalError("Not able to convert UIImage to CIImage")
        }
        detectScene(image: ciImage)
    }

    //MARK: - Methods
    func detectScene(image: CIImage) {
        answerLabel.text = "Detecting image..."
        
        // Load the ML model through its generated class
        guard let model = try? VNCoreMLModel(for : Inceptionv3().model) else {
            fatalError("Can't load Inception ML model")
        }
        
        // Create a Vision request with completion handler
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("Unexpected result type from VNCoreMLRequest")
            }
            
            // Update UI on main queue
            DispatchQueue.main.async { [weak self] in
                self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's \(topResult.identifier)"
            }
        }
        
        // Run the Core ML model classifier on global dispatch queue
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    // MARK: - IBActions
    @IBAction func pickImage(_ sender: Any) {
        // initialize the action sheet to provide option to the user to choose image from camera or photo library
        let alert = UIAlertController(title: "Let's get a picture from:", message: "", preferredStyle: .actionSheet)
        let libButton = (UIAlertAction(title: "Photo Library", style: .default) { action in
            self.imageController.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(self.imageController, animated: true, completion: nil)
        })
        let cameraButton = UIAlertAction(title: "Camera", style: .default) { action in
            print("Take Photo")
            if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
                self.imageController.sourceType = UIImagePickerController.SourceType.camera
                self.present(self.imageController, animated: true, completion: nil)
            }
            else {
                print("Camera not available")
                // show the alert if no camera found
                let alertVC = UIAlertController(
                    title: "No Camera",
                    message: "Sorry, this device has no camera",
                    preferredStyle: .alert)
                let okAction = UIAlertAction(
                    title: "OK",
                    style:.default,
                    handler: nil)
                alertVC.addAction(okAction)
                self.present(
                    alertVC,
                    animated: true,
                    completion: nil)
            }
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { action  in
            print("Cancel Pressed")
        }
        
        alert.addAction(cameraButton)
        alert.addAction(libButton)
        alert.addAction(cancelButton)
        
        self.present(alert, animated: true)
    }
    
}

