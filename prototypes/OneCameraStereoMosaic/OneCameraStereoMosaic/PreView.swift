import Foundation
import UIKit

class PreView : UIViewController {
    var leftImage: UIImage?
    var rightImage: UIImage?
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.leftImage != nil {
            self.leftImageView.image = self.leftImage
        }
        if self.rightImage != nil {
            self.rightImageView.image = self.rightImage
        }
    }

    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
