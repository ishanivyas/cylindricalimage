import UIKit

class PhotoViewController: UIViewController {
    var takenPhoto:UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let availableImage = takenPhoto {
            imageView.image = availableImage
        }
    }

    @IBAction func goBack(_ sender: Any) {
       self.dismiss(animated: true, completion: nil)
    }
}
