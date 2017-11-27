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
/*-
    func pixels4() -> [UInt8]? {
        guard let i = self.cgImage else { return nil }
        let w       = self.size.width  ;   let wi = i.width
        let h       = self.size.height ;   let hi = i.height
        let pixels  = [UInt8](repeating:0, count:4*wi*hi)
        let ctx     = CGContext.init(
            data:             UnsafeMutablePointer(mutating: pixels),  // Pointer to data
            width:            wi,   // Width of bitmap
            height:           hi,   // Height of bitmap
            bitsPerComponent: 8,    // Bits per component
            bytesPerRow:      0,    // Bytes per row (0 => auto)
            space:            i.colorSpace!,                           // Colorspace
            bitmapInfo:       CGImageAlphaInfo.noneSkipLast.rawValue   // Bitmap info flags
        )
        ctx?.draw(i, in: CGRect(x:0, y:0, width:w, height:h))
        return pixels
    }
-*/
    static func from(bytes b:UnsafeMutableRawPointer, width w:Int, height h:Int, _ bpp:Int) -> UIImage? {
        let l          = w*h
        let data       = NSData(bytesNoCopy:b, length:l)
        let provider   = CGDataProvider(data: data)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image      = CGImage(
            width:             w,
            height:            h,
            bitsPerComponent:  8,
            bitsPerPixel:      bpp,
            bytesPerRow:       (bpp>>3)*w,
            space:             colorSpace,
            bitmapInfo:        CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider:          provider!, // CGDataProviderRef
            decode:            nil,
            shouldInterpolate: false,
            intent:            CGColorRenderingIntent.defaultIntent
        )!;
        return UIImage(cgImage:image)
    }

    static func fromCopy(bytes b:UnsafeMutableRawPointer, width w:Int, height h:Int, _ bpp:Int) -> UIImage? {
        let l          = w*h
        let data       = NSData(bytes: b, length: l)
        let provider   = CGDataProvider(data: data)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let image      = CGImage(
            width:             w,
            height:            h,
            bitsPerComponent:  8,
            bitsPerPixel:      bpp,
            bytesPerRow:       (bpp>>3)*w,
            space:             colorSpace,
            bitmapInfo:        CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider:          provider!, // CGDataProviderRef
            decode:            nil,
            shouldInterpolate: false,
            intent:            CGColorRenderingIntent.defaultIntent
            )!;
        return UIImage(cgImage:image)
    }
    
    func scaledBy(ratio r:CGFloat) -> UIImage? {
        let scaledSize = CGSize(width:  r,
                                height: r)
        UIGraphicsBeginImageContext(scaledSize)
        self.draw(in: CGRect(origin: CGPoint(x:0, y:0), size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
