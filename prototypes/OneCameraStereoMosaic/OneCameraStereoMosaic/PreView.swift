import Foundation
import UIKit

// This is the view that shows the stitched left and right images.
class PreView : PortraitViewController, UIScrollViewDelegate {
    var leftImage: UIImage?
    var rightImage: UIImage?

    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContent: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self;
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if leftImage != nil {
            leftImageView.image = leftImage
        }


        if rightImage != nil {
            rightImageView.image = rightImage
        }

        let size = CGSize(width: max((leftImage?.cgImage?.width)!,
                                     (rightImage?.cgImage?.width)!),
                          height: (leftImage?.cgImage?.height)!
                                  + (rightImage?.cgImage?.height)!)
        scrollView.contentSize = size
    }

    func viewForZooming(in scrollView:UIScrollView) -> UIView? {
        return self.scrollContent;
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
