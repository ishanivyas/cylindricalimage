import Foundation
import UIKit

extension UIImage {
    func pixels() -> [UInt8]? {
        let size       = self.size
        let dataSize   = 4 * size.width * size.height
        var pixelData  = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context    = CGContext(data:             &pixelData,
                                   width:            Int(size.width),
                                   height:           Int(size.height),
                                   bitsPerComponent: 8,
                                   bytesPerRow:      4 * Int(size.width),
                                   space:            colorSpace,
                                   bitmapInfo:       CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage,
                      in: CGRect(x: 0, y: 0,
                                 width: size.width, height: size.height))        
        return pixelData
    }
}
