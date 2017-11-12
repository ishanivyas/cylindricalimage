import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let band_width = 64

    var previewLayer:CALayer!
    let captureSession = AVCaptureSession()
    var captureDevice:AVCaptureDevice!
    var dataOutput:AVCaptureVideoDataOutput!
    
    @IBOutlet var scanView : ScanView?
    var left:Array<UIImage> = []
    var right:Array<UIImage> = []
    var started = false
    
    var nFrames : UInt64 = 0
    var lastFrameAt_ns : UInt64 = 0
    var avgInterFrameDelay_ns : UInt64 = 0
    var maxInterFrameDelay_ns : UInt64 = 0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
            startSession()
        }
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
    func startSession() {
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            captureSession.commitConfiguration()
            captureSession.startRunning()
        }
    }

    // Stop data from reaching the dataOutput.
    func stopSession() {
        captureSession.stopRunning()
        captureSession.removeOutput(dataOutput)
        captureSession.commitConfiguration()
    }

    // Start accumulating data into our separate mosaics.
    func startCapture() {
        dataOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(label: "edu.berkeley.captureQueue")
        )
    }

    // Stop accumulating data into our separate mosaics.
    func stopCapture() {
        dataOutput.setSampleBufferDelegate(nil, queue: nil)
    }

    @IBAction func toggleCapture(_ sender: Any) {
        started = !started
        if (!started) {
            // New state is "not started".  Stop capturing, stitch, and present
            // the images we constructed.
            stopCapture()
            startPreview()

            // Present some statistics and reset them for a new capture.
            avgInterFrameDelay_ns = avgInterFrameDelay_ns / (1+nFrames)
            print("Stopped capture after \(nFrames) frames")
            print("avg: \(avgInterFrameDelay_ns)\tmax: \(maxInterFrameDelay_ns)")
            nFrames = 1
            avgInterFrameDelay_ns = 0
            maxInterFrameDelay_ns = 0

            // Stitch the images
            let leftImage = stitchImages(left)
            let rightImage = stitchImages(right)

            // Show the two stitched images
            let PreView = UIStoryboard(
                name: "Main", bundle: nil
            ).instantiateViewController(withIdentifier: "PreView") as! PreView

            PreView.leftImage = leftImage
            PreView.rightImage = rightImage

            DispatchQueue.main.async {
                self.present(PreView, animated: true, completion: {})
            }

            //TODO// save the images into a format that can be used by Google Cardboard.
        } else {
            print("starting capture")
            stopPreview()
            startCapture()
        }
    }
    
    // Function to accumulate images for later stitching.  We want to keep this
    // quick because we want low inter-frame delays.
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // Get the photo from the session.
        let images = self.getImagesFromSampleBuffer(buffer: sampleBuffer)
        if images == nil {
            return
        }

        left.append(images![0])
        right.append(images![1])

        self.scanView?.left = self.left.last!
        self.scanView?.right = self.right.last!

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
    
    // Get the sequences of left-images and right images and stitch then into
    // two images.
    // CMSampleBuffer --> CVPixelBuffer --> CIImage --> CGImage --> UIImage
    func getImagesFromSampleBuffer (buffer:CMSampleBuffer) -> [UIImage]? {
        #if true
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let bw = band_width
            let offset = 64
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            let xl = offset
            let xr = w - offset - bw
            let y = 0
            
            let leftBand = CGRect(x: xl, y: y, width: bw, height: h)
            let rightBand = CGRect(x: xr, y: y, width: bw, height: h)

            let leftCGImage = context.createCGImage(ciImage, from: leftBand)
            let rightCGImage = context.createCGImage(ciImage, from: rightBand)
            if leftCGImage != nil && rightCGImage != nil {
                let leftUIImage = UIImage(cgImage: leftCGImage!, scale: UIScreen.main.scale, orientation: UIImageOrientation.right)
                let rightUIImage = UIImage(cgImage: rightCGImage!, scale: UIScreen.main.scale, orientation: UIImageOrientation.right)
                return [leftUIImage, rightUIImage]
            }
        }
        return nil
        #endif

        #if false
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let w = CVPixelBufferGetWidth(pixelBuffer)
            let h = CVPixelBufferGetHeight(pixelBuffer)
            let r = CVPixelBufferGetBytesPerRow(pixelBuffer)
            let bytesPerPixel = r/w


            let buffer = CVPixelBufferGetBaseAddress(pixelBuffer)
            UIGraphicsBeginImageContext(CGSize(width: w, height:h))
            let context = UIGraphicsGetCurrentContext()
            if let data = context?.data {
                data.copyBytes(from: buffer!, count: w*h*4) // Error: found nil
            }
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if img != nil {
                let bw = band_width
                let offset = 64
                let xl = offset
                let xr = w - offset - bw
                let leftBand = CGRect(x: xl, y: 0, width: bw, height: h)
                let rightBand = CGRect(x: xr, y: 0, width: bw, height: h)
                return [UIImage(cgImage: (img!.cgImage?.cropping(to: leftBand))!),
                        UIImage(cgImage: (img!.cgImage?.cropping(to: rightBand))!)]
            }
        }
        return nil
        #endif
    }
    
    func stitchImages (_ images:Array<UIImage>) -> UIImage? {
        let width = images.count * band_width
        let height = images[0].cgImage?.height

        UIGraphicsBeginImageContext(CGSize(width:width, height:height!))
        var x = 0.0
        for img in images {
            img.draw(at: CGPoint(x: x, y: 0))
            x += Double(band_width)
        }
        let result:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
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
