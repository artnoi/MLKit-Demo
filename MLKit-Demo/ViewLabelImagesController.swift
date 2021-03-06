import UIKit
import Firebase

class ViewLabelImagesController: UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    
    lazy var vision = Vision.vision()
    let imagePicker = UIImagePickerController()
    
    
    var frameSublayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        indicator.isHidden = true
        indicator.stopAnimating()
        
        
        
        imageView.layer.addSublayer(frameSublayer)
        
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
    
    
    /// Detects labels on the specified image and prints the results.
    func detectLabels() {
        guard let image = imageView.image else { return }
        
        // [START config_label]
      //  let options = VisionLabelDetectorOptions(
       //     confidenceThreshold: Constants.labelConfidenceThreshold
       // )
        // [END config_label]
        // [START init_label]
       // let labelDetector = vision.labelDetector(options: options)  // Check console for errors.
        // Or, to use the default settings:
         let labelDetector = vision.labelDetector()
        // [END init_label]
        // Define the metadata for the image.
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = detectorOrientationFrom(image.imageOrientation)
        
        // Initialize a VisionImage object with the given UIImage.
        let visionImage = VisionImage(image: image)
        visionImage.metadata = imageMetadata
        
        // [START detect_label]
        labelDetector.detect(in: visionImage) { (labels, error) in
            guard error == nil, let labels = labels, !labels.isEmpty else {
                // Error. You should also check the console for error messages.
                // [START_EXCLUDE]
                let errorString = error?.localizedDescription ?? ""
                print("Label detection failed with error: \(errorString)")
                self.textView.text = "Label detection: \(errorString)"
                // [END_EXCLUDE]
                return
            }
            
            // Labeled image
            // [START_EXCLUDE]
//            self.logExtrasForTesting(labels: labels)
            self.textView.text = labels.map { label -> String in
                // TODO(b/78151345): Draw a frame for image labeling detection in the sample app.
                "Label: \(label.label), Confidence: \(label.confidence), EntityID: " +
                "\(label.entityID), Frame: \(label.frame)"
                }.joined(separator: "\n")
            // [END_EXCLUDE]
        }
        // [END detect_label]
    }
    
    
    
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
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
        
        drawFrame(featureRectScaled)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect) {
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = Constants.lineColor
        rectLayer.fillColor = Constants.fillColor
        rectLayer.lineWidth = Constants.lineWidth
        frameSublayer.addSublayer(rectLayer)
    }
    
    /// Returns the `VisionDetectorImageOrientation` from the given `UIImageOrientation`.
    private func detectorOrientationFrom(
        _ imageOrientation: UIImageOrientation
        ) -> VisionDetectorImageOrientation {
        switch imageOrientation {
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
    
}


extension ViewLabelImagesController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image")
            indicator.isHidden = true
            indicator.stopAnimating()
        }
        
        indicator.isHidden = true
        indicator.stopAnimating()
        imageView.image = image
        detectLabels()
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




