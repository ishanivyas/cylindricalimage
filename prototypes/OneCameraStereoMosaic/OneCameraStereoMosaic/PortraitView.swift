import Foundation
import UIKit

class PortraitViewController : UIViewController {
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
