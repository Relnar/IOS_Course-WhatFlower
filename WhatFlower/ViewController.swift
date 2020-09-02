//
//  ViewController.swift
//  WhatFlower
//
//  Created by Pierre-Luc Bruyere on 2018-11-01.
//  Copyright © 2018 Pierre-Luc Bruyere. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
  // MARK: - Attributes

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var cameraButton: UIBarButtonItem!
  @IBOutlet weak var libraryButton: UIBarButtonItem!
  @IBOutlet weak var infoLabel: UILabel!

  private let imagePicker = UIImagePickerController()

  private let wikipediaURl = "https://en.wikipedia.org/w/api.php"

  // MARK: -

  override func viewDidLoad()
  {
    super.viewDidLoad()

    imagePicker.allowsEditing = false
    imagePicker.delegate = self
  }

  private func detect(flowerImage: CIImage)
  {
    guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)
    else
    {
      fatalError("Cannot import model")
    }

    let request = VNCoreMLRequest(model: model)
    { (request, error) in
      guard let classification = request.results?.first as? VNClassificationObservation
      else
      {
        fatalError("Error in classification")
      }

      self.navigationItem.title = classification.identifier.capitalized

      self.requestInfo(flowerName: classification.identifier)

      self.cameraButton.isEnabled = true
      self.libraryButton.isEnabled = true
    }

    let handler = VNImageRequestHandler(ciImage: flowerImage)
    do
    {
      try handler.perform([request])
    }
    catch
    {
      print("Request handler error \(error)")
    }
  }

  func requestInfo(flowerName: String)
  {
    let parameters : [String:String] = [
      "format" : "json",
      "action" : "query",
      "prop" : "extracts|pageimages",
      "exintro" : "",
      "explaintext" : "",
      "titles" : flowerName,
      "indexpageids" : "",
      "redirects" : "1",
      "pithumbsize" : "500"
      ]

    Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON
    { (response) in
      if response.result.isSuccess
      {
        let json = JSON(response.result.value!)
        let pageid = json["query"]["pageids"][0].stringValue
        self.infoLabel.text = json["query"]["pages"][pageid]["extract"].stringValue

        let flowerImageURL = json["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
      }
    }
  }

  // MARK: - Image Picker Controller Delegate methods

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
  {
    cameraButton.isEnabled = false
    libraryButton.isEnabled = false

    if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
    {
      guard let ciImage = CIImage(image: image)
      else
      {
        fatalError("Could not convert image to CIImage")
      }

      detect(flowerImage: ciImage)
    }

    dismiss(animated: true, completion: nil)
  }

  // MARK: - Bar buttons

  @IBAction func cameraTapped(_ sender: UIBarButtonItem)
  {
    imagePicker.sourceType = .camera

    present(imagePicker, animated: true, completion: nil)
  }

  @IBAction func libraryTapped(_ sender: UIBarButtonItem)
  {
    imagePicker.sourceType = .photoLibrary

    present(imagePicker, animated: true, completion: nil)
  }
}

