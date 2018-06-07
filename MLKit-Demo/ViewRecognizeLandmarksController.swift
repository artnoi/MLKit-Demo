import UIKit
import Firebase

class ViewRecognizeLandmarksController: UIViewController {
    
    
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
    
    
    /// Detects landmarks on the specified image and draws a frame for them.
    func detectLandmarksCloud() {
        guard let image = imageView.image else { return }
        
        // Create a landmark detector.
        // [START config_landmark_cloud]
        let options = VisionCloudDetectorOptions()
        options.modelType = .latest
        options.maxResults = 20
        // [END config_landmark_cloud]
        // [START init_landmark_cloud]
        let landmarkDetector = vision.cloudLandmarkDetector(options: options)
        // Or, to use the default settings:
        // let landmarkDetector = vision?.cloudLandmarkDetector()
        // [END init_landmark_cloud]
        // Initialize a VisionImage object with a UIImage.
        // [START init_image]
        let visionImage = VisionImage(image: image)
        // [END init_image]
        // Define the metadata for the image.
        // [START set_image_metadata]
        let imageMetadata = VisionImageMetadata()
        imageMetadata.orientation = .topLeft
        
        visionImage.metadata = imageMetadata
        // [END set_image_metadata]
        // [START detect_landmarks_cloud]
        landmarkDetector.detect(in: visionImage) { (landmarks, error) in
            guard error == nil, let landmarks = landmarks, !landmarks.isEmpty else {
                // [START_EXCLUDE]
                let errorString = error?.localizedDescription ?? ""
                print("Landmark detection failed with error: \(errorString)")
                self.textView.text = "Landmark Detection: \(errorString)"
                // [END_EXCLUDE]
                return
            }
            
            // Recognized landmarks
            // [START_EXCLUDE]
            self.textView.text = landmarks.map { landmark -> String in
                self.addFrameView(
                    featureFrame: landmark.frame,
                    imageSize: image.size,
                    viewFrame: self.imageView.frame
                )
//                self.logExtrasforTesting(landmark: landmark)
                return "Frame: \(landmark.frame)"
                }.joined(separator: "\n")
            // [END_EXCLUDE]
        }
        // [END detect_landmarks_cloud]
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


extension ViewRecognizeLandmarksController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Couldn't load image")
            indicator.isHidden = true
            indicator.stopAnimating()
        }
        
        indicator.isHidden = true
        indicator.stopAnimating()
        imageView.image = image
        detectLandmarksCloud()
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





