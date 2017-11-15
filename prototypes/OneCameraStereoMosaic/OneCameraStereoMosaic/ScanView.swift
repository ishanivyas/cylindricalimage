import Foundation
import UIKit

// This is the view that shows the vertical bands extracted from the camera as
// the user pans the scene.
class ScanView : UIView {
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!

    var left : UIImage {
        get { return self.left }
        set(new) {
            DispatchQueue.main.async {
                self.leftImageView.image = new
                self.leftImageView.setNeedsDisplay()
            }
        }
    }
    var right : UIImage {
        get { return self.right }
        set(new) {
            DispatchQueue.main.async {
                self.rightImageView.image = new
                self.rightImageView.setNeedsDisplay()
            }
        }
    }
}
