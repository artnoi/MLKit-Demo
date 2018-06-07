import UIKit

class ViewMenuMLKit: UIViewController {

    @IBOutlet weak var tableMenuMLKit: UITableView!
    
    var menuMLKits = ["Text Recognize", "Face Detection", "Barcode Scanning", "Image Labeling", "Landmark Detection"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

extension ViewMenuMLKit: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuMLKits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuMLKitCell", for: indexPath as IndexPath) as! MenuMLKitCell
        cell.labelMenuMLKit.text = menuMLKits[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let segueIdentifier = menuMLKits[indexPath.row]
        self.performSegue(withIdentifier: segueIdentifier, sender: "")
    }
}

