import Foundation
import UIKit

class PortraitViewController : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        //-UIDevice.setValue(UIInterfaceOrientation.portrait, forKey: "orientation")
        //-UIDevice.current.setValue(UIInterfaceOrientation.portrait, forKey: "orientation")
    }    
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        get { return UIInterfaceOrientationMask.portrait }
    }
    
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        get { return UIInterfaceOrientation.portrait }
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return false
    }
    
    override var shouldAutorotate: Bool {
        get { return false }
    }
}
