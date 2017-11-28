import UIKit
import AVFoundation

class ViewController: PortraitViewController,
                      AVCaptureVideoDataOutputSampleBufferDelegate {
    var stereo : OCVStereo!

    // AVCapture Stuff
    var previewLayer:CALayer!
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    var dataOutput:AVCaptureVideoDataOutput!
    var started = false

    @IBOutlet var scanView : ScanView?      // Visualizes the bands we are capturing.
    @IBOutlet var startButton : UIButton!   // Starts slicing out the bands.

    var nFrames : UInt64 = 0
    var lastFrameAt_ns : UInt64 = 0
    var avgInterFrameDelay_ns : UInt64 = 0
    var maxInterFrameDelay_ns : UInt64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.stereo = OCVStereo(stripWidth: 1, forScale: 1.0)

        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        if let availableDevices = AVCaptureDeviceDiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: AVMediaTypeVideo,
            position: .back
        ).devices {
            captureDevice = availableDevices.first // assign first object here
            do {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(captureDeviceInput)
            } catch {
                print(error.localizedDescription)
            }

            startPreview()
            configureOutput()
            startAVCaptureSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func configureOutput() {
        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            ((kCVPixelBufferPixelFormatTypeKey as NSString) as String):
                NSNumber(value:kCVPixelFormatType_32BGRA)
        ]
        dataOutput.alwaysDiscardsLateVideoFrames = true
    }

    // Setup preview layer so that a running capture session can place live
    // imagery into the UI.
    func startPreview() {
        if let layer = AVCaptureVideoPreviewLayer(session: captureSession) {
            layer.videoGravity = AVLayerVideoGravityResizeAspect
            self.previewLayer = layer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
        }
    }

    // Hide/remove the preview later.
    func stopPreview() {
        self.previewLayer.removeFromSuperlayer()
        self.previewLayer = nil
    }

    // Start capturing the data from the camera and put it into our dataOutput.
    func startAVCaptureSession() {
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            captureSession.commitConfiguration()
            captureSession.startRunning()
        }
    }

    // Stop data from reaching the dataOutput.
    func stopAVCaptureSession() {
        captureSession.stopRunning()
        captureSession.removeOutput(dataOutput)
        captureSession.commitConfiguration()
    }

    // Start accumulating data into our separate mosaics.
    func startMosaicCapture() {
        dataOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "edu.berkeley.captureQueue")
        )
    }

    // Stop accumulating data into our separate mosaics.
    func stopMosaicCapture() {
        dataOutput.setSampleBufferDelegate(nil, queue: nil)
    }

    @IBAction func toggleCapture(_ sender: Any) {
        started = !started
        if (!started) {
            // New state is "not started".  Stop capturing, stitch, and present
            // the images we constructed.
            stopMosaicCapture()
            startPreview()
            
            // Present some statistics and reset them for a new capture.
            avgInterFrameDelay_ns = avgInterFrameDelay_ns / (1+nFrames)
            print("Stopped capture after \(nFrames) frames")
            print("avg: \(avgInterFrameDelay_ns)\tmax: \(maxInterFrameDelay_ns)")
            nFrames = 1
            avgInterFrameDelay_ns = 0
            maxInterFrameDelay_ns = 0

            // Show the two stitched images
            let PreView = UIStoryboard(
                name: "Main", bundle: nil
            ).instantiateViewController(withIdentifier: "PreView") as! PreView

            // Stitch the images
            self.stereo.stitchPanos();
            PreView.leftImage = self.stereo.leftPano();
            PreView.rightImage = self.stereo.rightPano();
                
            DispatchQueue.main.async {
                self.startButton.titleLabel?.text = "Done"
                self.present(PreView, animated: true, completion: {})
            }

            //TODO// save the images into a format that can be used by Google Cardboard.
        } else {
            DispatchQueue.main.async {
                self.startButton.titleLabel?.text = "Cap..."
            }
            stopPreview()
            startMosaicCapture()
        }
    }
    
    // CAPTURE DELEGATE
    // Function to accumulate images for later stitching.  We want to keep this
    // quick because we want low inter-frame delays.
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let uiImage = self.getImageFromSampleBuffer(buffer: sampleBuffer)!

        // Save the image into the stereo pair.
        let delta = self.stereo.append(uiImage)
        DispatchQueue.main.async {
            let d = String(format: "%1.3f", delta)
            let t = self.startButton.titleLabel?.text
            if t != d {
                self.startButton.titleLabel?.text = d
            }
        }

        // Update the UI
        self.scanView?.left = rot90(dup(self.stereo.lastLeft()))
        self.scanView?.right = rot90(dup(self.stereo.lastRight()))

        DispatchQueue.main.async {
            self.stereo.lastLeft()
        }
        // Keep statistics on inter-frame delay
        nFrames = nFrames + 1
        let now_ns = mach_absolute_time()
        let delta_ns = now_ns - lastFrameAt_ns
        avgInterFrameDelay_ns += delta_ns
        if maxInterFrameDelay_ns < delta_ns {
            maxInterFrameDelay_ns = delta_ns
        }
        lastFrameAt_ns = now_ns

        //TODO// capture camera pose information (position, direction, camera settings).
        //TODO// show positions user should move camera to for next photos.
    }
    
    // Convert a CMSampleBuffer into a UIImage.
    // CMSampleBuffer --> CVPixelBuffer --> CIImage --> CGImage --> UIImage
    func getImageFromSampleBuffer(buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            // Convert the buffer into a UIImage.
            let wi = CVPixelBufferGetWidth(pixelBuffer) ; let w = Double(wi)
            let hi = CVPixelBufferGetHeight(pixelBuffer); let h = Double(hi)
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            let cgImage = context.createCGImage(ciImage,
                                                from: CGRect(x:0.0, y:0.0, width:w, height:h))
            return UIImage(cgImage: cgImage!)
        }
        return nil
    }

    /* ********************************************************************** */

    func describe(_ image:UIImage, _ prefix:String) {
        let h = image.cgImage!.height
        let w = image.cgImage!.width
        print("\(prefix) \(w) x \(h)")
    }
    
    func dup(_ image:UIImage) -> UIImage {
        let h = image.cgImage!.height
        let w = image.cgImage!.width
        UIGraphicsBeginImageContext(CGSize(width:w, height:h))
        image.draw(at: CGPoint(x: 0.0, y: 0.0))
        let result:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }

    func rot90(_ image:UIImage) -> UIImage {
        let unrotated:UIImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: UIImageOrientation.upMirrored)
        let rotated:UIImage = UIImage(cgImage: unrotated.cgImage!, scale: unrotated.scale, orientation: UIImageOrientation.rightMirrored)
        return rotated
    }

    func stitchImages (_ images:Array<UIImage>) -> UIImage? {
        return self.stereo.stitch()
    }
}
