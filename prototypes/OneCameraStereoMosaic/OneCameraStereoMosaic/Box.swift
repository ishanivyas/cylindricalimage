import Foundation
import SceneKit

class Box: SCNNode {
    lazy var box: SCNNode = Box().makeBox()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeBox() -> SCNNode {
        let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
        return convertToNode(geometry: box)
    }
    
    func convertToNode(geometry: SCNGeometry) -> SCNNode {
        for material in geometry.materials {
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = false
        }
        
        let node = SCNNode(geometry: geometry)
        self.addChildNode(node)
        return node
    }

    func resizeTo(extent: Float) {
        var (min, max) = boundingBox
        max.x = extent
        update(minExtents: min, maxExtents: max)
    }
    
    func update(minExtents: SCNVector3, maxExtents: SCNVector3) {
        guard let scnBox = box.geometry as? SCNBox else {
            fatalError("Geometry is not SCNBox")
        }
        
        // Normalize the bounds so that min is always < max
        let absMin = SCNVector3(x: min(minExtents.x, maxExtents.x), y: min(minExtents.y, maxExtents.y), z: min(minExtents.z, maxExtents.z))
        let absMax = SCNVector3(x: max(minExtents.x, maxExtents.x), y: max(minExtents.y, maxExtents.y), z: max(minExtents.z, maxExtents.z))
        
        // Set the new bounding box
        boundingBox = (absMin, absMax)
        
        // Calculate the size vector
        let size = absMax - absMin
        
        // Take the absolute distance
        let absDistance = CGFloat(abs(size.x))
        
        // The new width of the box is the absolute distance
        scnBox.width = absDistance
        
        // Give it a offset of half the new size so they box remains fixed
        let offset = size.x * 0.5
        
        // Create a new vector with the min position of the new bounding box
        let vector = SCNVector3(x: absMin.x, y: absMin.y, z: absMin.z)
        
        // And set the new position of the node with the offset
        box.position = vector + SCNVector3(x: offset, y: 0, z: 0)
    }
}

extension SCNVector3 {
    func normL1() -> SCNFloat {
        return abs(x) + abs(y) + abs(z)
    }
    func normL2() -> SCNFloat {
        return sqrt(x*x + y*y + z*z)
    }
}

func verticalAngleBetween(a: SCNVector3, b: SCNVector3) -> SCNFloat {
    return atan2(a.z - b.z, a.y - b.y)
}

func horizontalAngleBetween(a: SCNVector3, b: SCNVector3) -> SCNFloat {
    return atan2(a.z - b.z, a.x - b.x)
}

func * (k: SCNFloat, v: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(v.x * k, v.y * k, v.z * k)
}

func * (v: SCNVector3, k: SCNFloat) -> SCNVector3 {
    return SCNVector3Make(v.x * k, v.y * k, v.z * k)
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}
