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
            #if false
                leftImageView.sizeToFit()
            #elseif false
                var l = rightImageView.frame
                l.origin.x = 0
                l.origin.y = 0
                l.size.height = (leftImage?.size.height)!
                l.size.width = (leftImage?.size.width)!
                leftImageView.frame = l
            #endif
        }


        if rightImage != nil {
            rightImageView.image = rightImage
            #if false
                rightImageView.sizeToFit()
            #elseif false
                var r = rightImageView.frame
                r.origin.x = 0
                r.origin.y = leftImageView.frame.size.height
                r.size.height = (rightImage?.size.height)!
                r.size.width = (rightImage?.size.width)!
                rightImageView.frame = r
            #endif
        }

        let size = CGSize(width: max((leftImage?.cgImage?.width)!,
                                     (rightImage?.cgImage?.width)!),
                          height: (leftImage?.cgImage?.height)!
                                  + (rightImage?.cgImage?.height)!)
//-        scrollContent.sizeToFit()
        scrollView.contentSize = size
    }

    func viewForZooming(in scrollView:UIScrollView) -> UIView? {
        return self.scrollContent;
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
