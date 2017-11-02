import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var navBar:UINavigationItem!

    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    var images:Array<UIImage> = []
    var previewLayer:CALayer!
    var takePhoto = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navBar.title = ""
        prepareCamera()
    }

    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        if let availableDevices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
            captureDevice = availableDevices.first // assign first object here
            beginSession()
        }
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(captureDeviceInput)
        } catch {
            print(error.localizedDescription)
        }

        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value:kCVPixelFormatType_32BGRA)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput) {
                captureSession.addOutput(dataOutput)
            }
            captureSession.commitConfiguration()
            
            dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "edu.berkeley.captureQueue"))
        }
    }

    @IBAction func takePhoto(_ sender: Any) {
        takePhoto = true
    }

    @IBAction func doneTakingPhotos(_ sender: Any) {
        //TODO// Call the stitcher
        let img = self.images[0]    //TODO// remove this once the stitcher starts returning results

        // We are done with the images.
        images = Array<UIImage>()
        self.navBar.title = ""
        self.navBar.titleView?.setNeedsDisplay()
        
        self.showStitchedImage(img)
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if !takePhoto {
            return
        }

        // Get the photo from the session.
        let image = self.getImageFromSampleBuffer(buffer: sampleBuffer)
        if image == nil {
            return
        }

        // Add the image to a list of images that should be part of the 360 view.
        self.images.append(image!)
        DispatchQueue.main.async {
            self.navBar.title = String(self.images.count)
        }

        //TODO// capture camera pose information (position, direction, camera settings).
        //TODO// show positions user should move camera to for next photos.

        takePhoto = false
    }

    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            if let image = context.createCGImage(ciImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        return nil
    }
    
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
    }

    func showStitchedImage(_ image:UIImage!) {
        // Display image that was just captured.
        let PanoViewC = UIStoryboard(
            name: "Main", bundle: nil
        ).instantiateViewController(withIdentifier: "PanoViewC") as! PanoramaViewController

        DispatchQueue.main.async {
            self.present(PanoViewC, animated: true, completion: {
                self.stopCaptureSession()
                //-PanoViewC.panorama.image = UIImage(named: "spherical")
                PanoViewC.panorama.image = image
            })
        }
    }

    /*-
    override func viewDidLoad() {
	super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
    }
    -*/
}

