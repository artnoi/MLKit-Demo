import UIKit
import Firebase

class ViewRecognizeTextController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    
    let imagePicker = UIImagePickerController()
    
    var textDetector: VisionTextDetector!
    var cloudTextDetector: VisionCloudTextDetector!
    
    var frameSublayer = CALayer()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        indicator.isHidden = true
        indicator.stopAnimating()
        
        textDetector = Vision().textDetector()
        cloudTextDetector = Vision().cloudTextDetector()
        
        imageView.layer.addSublayer(frameSublayer)
        
    }
    
    func detectTexts(image: UIImage) {
//        guard let image = imageView.image else { return }

        // Create a text detector.
        // [START init_text]
        // [END init_text]
        // Initialize a VisionImage with a UIImage.
        let visionImage = VisionImage(image: image)

        let metadata = VisionImageMetadata()
        metadata.orientation = .rightTop
        visionImage.metadata = metadata

        // [START detect_text]
        textDetector.detect(in: visionImage) { (features, error) in
            guard error == nil, let features = features, !features.isEmpty else {
                // Error. You should also check the console for error messages.
                // [START_EXCLUDE]
                let errorString = error?.localizedDescription ?? "No results returned."
                self.textView.text = "Text detection failed with error: \(errorString)"
                // [END_EXCLUDE]
                return
            }

            // Recognized and extracted text
            print("Detected text has: \(features.count) blocks")
            // [START_EXCLUDE]
//            self.textView.text = features.map { feature in
//                self.addFrameView(
//                    featureFrame: feature.frame,
//                    imageSize: image.size,
//                    viewFrame: self.imageView.frame
//                )
//                return "Text: \(feature.text)"
//                }.joined(separator: "\n")
            // [END_EXCLUDE]
        }
        // [END detect_text]
    }
    
    // MARK: Text Recognition
    
    func runTextRecognition(with image: UIImage) {
        let visionImage = VisionImage(image: image)
        textDetector.detect(in: visionImage) { features, error in
            self.processResult(from: features, error: error)
        }
    }
    
    
    
    // MARK: Image Drawing
    
    func processResult(from text: [VisionText]?, error: Error?) {
        removeFrames()
        guard let features = text, let image = imageView.image else {
            return
        }
        for text in features {
            if let block = text as? VisionTextBlock {
                for line in block.lines {
                    for element in line.elements {
                        self.addFrameView(
                            featureFrame: element.frame,
                            imageSize: image.size,
                            viewFrame: self.imageView.frame,
                            text: element.text
                        )
                    }
                }
            }
        }
        
        self.textView.text = features.map { feature in
            self.addFrameView(
                featureFrame: feature.frame,
                imageSize: image.size,
                viewFrame: self.imageView.frame
            )
            return "Text: \(feature.text)"
            }.joined(separator: "\n")
    }
    
    
    
    
    /// Converts a feature frame to a frame UIView that is displayed over the image.
    ///
    /// - Parameters:
    ///   - featureFrame: The rect of the feature with the same scale as the original image.
    ///   - imageSize: The size of original image.
    ///   - viewRect: The view frame rect on the screen.
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect, text: String? = nil) {
        print("Frame: \(featureFrame).")
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
        
        drawFrame(featureRectScaled, text: text)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect, text: String? = nil) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = Constants.lineColor
        rectLayer.fillColor = Constants.fillColor
        rectLayer.lineWidth = Constants.lineWidth
        if let text = text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.fontSize = 12.0
            textLayer.foregroundColor = Constants.lineColor
            let center = CGPoint(x: rect.midX, y: rect.midY)
            textLayer.position = center
            textLayer.frame = rect
            textLayer.alignmentMode = kCAAlignmentCenter
            textLayer.contentsScale = UIScreen.main.scale
            frameSublayer.addSublayer(textLayer)
        }
        frameSublayer.addSublayer(rectLayer)
    }
    
    private func removeFrames() {
        guard let sublayers = frameSublayer.sublayers else { return }
        for sublayer in sublayers {
            guard let frameLayer = sublayer as CALayer? else {
                print("Failed to remove frame layer.")
                continue
            }
            frameLayer.removeFromSuperlayer()
        }
    }
    
    func detectorOrientation(in image: UIImage) -> VisionDetectorImageOrientation {
        switch image.imageOrientation {
        case .up:
            return .topLeft
        case .down:
            return .bottomRight
        case .left:
            return .leftBottom
        case .right:
            return .rightTop
        case .upMirrored:
            return .topRight
        case .downMirrored:
            return .bottomLeft
        case .leftMirrored:
            return .leftTop
        case .rightMirrored:
            return .rightBottom
        }
    }
    
    @IBAction func selectImageClick(_ sender: Any) {

        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func openGallary() {
        indicator.isHidden = false
        indicator.startAnimating()
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func openCamera() {
        
        indicator.isHidden = false
        indicator.startAnimating()
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}


extension ViewRecognizeTextController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image")
            indicator.isHidden = true
            indicator.stopAnimating()
        }
        
        indicator.isHidden = true
        indicator.stopAnimating()
        imageView.image = image
        runTextRecognition(with: image)
        detectTexts(image: image)

        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        indicator.isHidden = true
        indicator.stopAnimating()
        dismiss(animated: true, completion: nil)
    }
}

fileprivate enum Constants {
    static let labelConfidenceThreshold: Float = 0.75
    static let lineWidth: CGFloat = 3.0
    static let lineColor = UIColor.yellow.cgColor
    static let fillColor = UIColor.clear.cgColor
}
