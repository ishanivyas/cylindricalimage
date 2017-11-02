import UIKit

class PanoramaViewController: UIViewController {
    @IBOutlet weak var panorama:PanoramaView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panorama.image = UIImage(named: "spherical")
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

