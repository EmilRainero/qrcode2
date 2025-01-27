// L Triangle sample code by Gary Bartos. Copyright 2021.
// If you need the code, use it! But bring no harm to people, bears, bats, or bees.
//
// The ImageFrame struct is listed first, then Triangle, Transform, and supporting types
// Test functions are provided at the very bottom.
// Run the entire playground and see the console for test output.

import CoreGraphics
import Foundation
import simd


/// A bounded coordinate frame for an image of finite extent. Nominally, X and Y coordinates are positive and are most meaningful within image bounds.
/// The coordinate frame is defined by its origin as the corner of the image rectangle,
/// the directions of the X and Y axes, and by the image size.
/// Vision framework and AVFoundation may use normalized coordinates from 0.0 to 1.0 for X and Y.
/// The rectangle has horizontal and vertical edges aligned with the screen of the iDevice.
/// The function triangleL( ) returns an "L" shape of points--top left,
/// bottom left, bottom right--that can be used to find the affine transform
/// from one coordinate frame to another.
/// +x and +y appear always to be defined so that coordinates are positive within the image.
struct ImageFrame: CustomStringConvertible {
    // MARK: - Properties
    /// The corner of the image when an iPhone is held in portrait mode, with the home button at bottom.
    private(set) var origin: Corner
    
    /// Direction of the x-Axis when an iPhone is held in portrait mode.
    /// TODO define change in direction for iPhone or iPad in different device orientations.
    private(set) var xAlignment: Alignment
    
    /// Direction of the y-Axis when an iPhone is held in portrait mode.
    /// Complement of the x-Axis direction.
    var yAlignment: Alignment {
        xAlignment.complement
    }
    
    /// Directions of the X and Y axes.
    /// The directions are determined by the Corner origin and whether X is aligned horizontally or vertically.
    var axes: (x: Direction, y: Direction) {
        switch origin {
        case .BottomLeft:
            return xAlignment == .Horizontal ? (.Right, .Up) : (.Up, .Right)
        case .BottomRight:
            return xAlignment == .Horizontal ? (.Left, .Up) : (.Up, .Left)
        case .TopLeft:
            return xAlignment == .Horizontal ? (.Right, .Down) : (.Down, .Right)
        case .TopRight:
            return xAlignment == .Horizontal ? (.Left, .Down) : (.Down, .Left)
        }
    }
    
    /// The width and height of the image. Normalized size will be (1.0, 1.0).
    private(set) var size: simd_float2
    
    var description: String {
        "\(origin.rawValue) origin: +X \(axes.x.rawValue), +Y \(axes.y.rawValue) size: \(size.x) x \(size.y)"
    }
    
    /// Size 1.0 x 1.0 for normalized coordinate frames
    static let normalizedSize = simd_float2(1.0, 1.0)
    
    // MARK: - Triangle L
    /// A triangle of points forming an "L" when we think of the iDevice (iPhone or iPad) held in portrait mode.
    /// ( top left, bottom left, bottom right ). The home button is at bottom.
    ///
    /// pt 1 .... [top right]
    ///   |        .
    /// pt 2 --- pt 3
    ///
    /// (home button)
    ///
    /// The left vertical leg of the triangle is size.y vertically.
    /// The bottom horizontal leg of the triangle is size.x horizontally.
    /// Direction.unitVector() provides the appropriate direction vector (1,0) for X and (0,1) for Y.
    /// The axes point across the device such that (x,y) coordinates in ANY frame are positive
    /// within the bounds of the device / image.
    /// An affine transform can be calculated from a triangle "L" in one coordinate system
    /// to a triangle "L" in another coordinate system.
    func triangleL() -> Triangle {
        let hz = size.x     // Horizontal dimension. Here size.x is the first component of simd_float2, which we treat as width.
        let vt = size.y     // Vertical dimension. Here size.y is the second component of simd_float2, which we treat as height.

        let x_hz = hz * simd_float2(1, 0)   // x-axis with horizontal dimension
        let x_vt = vt * simd_float2(1, 0)   // x-axis with vertical dimension
        
        let y_hz = hz * simd_float2(0, 1)   // y-axis with horizontal dimension
        let y_vt = vt * simd_float2(0, 1)   // y-axis with vertical dimension
        
        let zero = simd_float2(0, 0)        // the origin of the current frame as coordinates rather than as a Corner
        
        // Define the triangle in point order:              top left -> bottom left -> bottom right
        switch origin {
        case .BottomLeft:
            if xAlignment == .Horizontal {
                return Triangle(y_vt, zero, x_hz)           //+y up -> origin -> +x right
            }
            else {
                return Triangle(x_vt, zero, y_hz)           //+x up -> origin -> +y right
            }
        case .BottomRight:
            if xAlignment == .Horizontal {
                return Triangle(x_hz + y_vt, x_hz, zero)    //+x left and +y up -> +x left -> origin
            }
            else {
                return Triangle(x_vt + y_hz, y_hz, zero)    //+x up and +y left -> +y left -> origin
            }
        case .TopLeft:
            if xAlignment == .Horizontal {
                return Triangle(zero, y_vt, x_hz + y_vt)    //origin -> +y down -> +x right and +y down
            }
            else {
                return Triangle(zero, x_vt, x_vt + y_hz)    //origin -> +x down -> +x down and +y right
            }
        case .TopRight:
            if xAlignment == .Horizontal {
                return Triangle(x_hz, x_hz + y_vt, y_vt)    //+x left -> +x left and +y down -> +y down
            }
            else {
                return Triangle(y_hz, x_vt + y_hz, x_vt)    //+y left -> +x down and +y left -> +x down
            }
        }
    }
     
    // MARK: - Initialization
    /// Initializes an ImageFrame in terms of its Corner origin,
    /// whether the x-Axis is .Horizontal or Vertical, and the size of the region
    /// bounded by the image when the device is held in the portrait orientation.
    init(origin: Corner, xAlignment: Alignment, size: simd_float2) {
        self.origin = origin
        self.xAlignment = xAlignment
        self.size = size
    }
    
    /// Initializes an ImageFrame given the top left, bottom left, and bottom right points of
    /// a triangle congruent to the "L triangle" and aligned with it (at least roughly).
    /// The three point arguments may not lie on image edges, and instead may correspond to an L shape
    /// somewhere in the image.
    /// Size is determined using the three points, and may not correspond to the full image size, in which case
    /// the purpose may simply be to determine the Corner and x-axis direction.
    init(topLeft: simd_float2, bottomLeft: simd_float2, bottomRight: simd_float2) {
        let hz = bottomRight - bottomLeft
        let vt = topLeft - bottomLeft
        let size = simd_float2(simd_length(hz), simd_length(vt))

        self.init(topLeft: topLeft, bottomLeft: bottomLeft, bottomRight: bottomRight, size: size)
    }
    
    /// Initializes an ImageFrame given the top left, bottom left, and bottom right points of
    /// a triangle congruent to the "L triangle" and aligned with it (at least roughly).
    /// The three point arguments may not lie on image edges, and instead may correspond to an L shape
    /// somewhere in the image.
    init(topLeft: simd_float2, bottomLeft: simd_float2, bottomRight: simd_float2, size: simd_float2) {
        // horizontal and vertical vectors from bottom left
        // ^
        // |
        //  -->
        
        let lr = simd_normalize(bottomRight - bottomLeft)  //unit vector pointing left to right
        let bt = simd_normalize(topLeft - bottomLeft)      //unit vector pointing bottom to top
        
        // x-direction is horizontal if x value from left to right is greater than x value from bottom to top (for normalized lengths)
        let xdir: Alignment = abs(lr.x) > abs(bt.x) ? .Horizontal : .Vertical

        // find the corner from which a vector to the center has (+x, +y) components
        let center = (topLeft + bottomRight)/2
        
        if (center - topLeft).x > 0 && (center - topLeft).y > 0 {
            self.init(origin: .TopLeft, xAlignment: xdir, size: size)
        }
        else if (center - bottomLeft).x > 0 && (center - bottomLeft).y > 0 {
            self.init(origin: .BottomLeft, xAlignment: xdir, size: size)
        }
        else if (center - bottomRight).x > 0 && (center - bottomRight).y > 0 {
            self.init(origin: .BottomRight, xAlignment: xdir, size: size)
        }
        else {
            self.init(origin: .TopRight, xAlignment: xdir, size: size)
        }
    }
    
    // MARK: - Operators
    static func == (lhs: ImageFrame, rhs: ImageFrame) -> Bool {
        return lhs.origin == rhs.origin
            && lhs.xAlignment == rhs.xAlignment
            && lhs.size == rhs.size
    }

    // MARK: - Transforms
    /// Affine transform (3x3) from the current frame to another frame.
    func transform(to: ImageFrame) -> float3x3? {
        return ImageFrame.transform(from: self, to: to)
    }
    
    /// Affine transform between frames. We are transforming from the triangle L in one frame to the
    /// triangle L in another frame.
    static func transform(from: ImageFrame, to: ImageFrame) -> float3x3? {
        if from.size.x == 0 || from.size.y == 0 || to.size.x == 0 || to.size.y == 0 {
            return nil
        }

        if from == to && from.size == to.size {
            return float3x3(1)
        }

        return Transform.affine(from: from.triangleL(), to: to.triangleL())
    }
}

/// Three points nominally defining a triangle, but possibly colinear.
struct Triangle: CustomStringConvertible {
    var point1: simd_float2
    var point2: simd_float2
    var point3: simd_float2
    
    /// Dependent on NumberFormatter extension. Mildly convenient.
    var description: String {
        let f = NumberFormatter()
        return f.string(self, descriptionDigits)
    }
    
    /// Digits used in description (e.g. if digits = 1, point1 (2,3) will be displayed as "(2.0, 3.0)"
    var descriptionDigits = 1
    
    init(_ point1: simd_float2, _ point2: simd_float2, _ point3: simd_float2) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
    }
    
    init(_ vector1: simd_float3, _ vector2: simd_float3, _ vector3: simd_float3) {
        point1 = vector1.toVector2()
        point2 = vector2.toVector2()
        point3 = vector3.toVector2()
    }

    /// Returns a triangle transformed by the 3x3 matrix.
    /// newTriangle = m * self
    func applying(_ t: float3x3) -> Triangle {
        let m = toMatrix()
        let p = t * m
        return try! Triangle.fromMatrix(p)
    }
    
    /// Three points are colinear if their determinant is zero. We assume close to colinear might as well be colinear.
    /// ```
    ///     | x1  x2  x3 |
    /// det | y1  y2  y3 |  = 0     -->    abs( det(M) )  < tolerance
    ///     |  1   1   1 |
    /// ```
    /// NOTE: transforms to and from normalized coordinates with a range (0.0, 1.0) for X and Y,
    /// the determinant of a matrix or its inverse can be quite small. For example, the transform
    /// from UI coordinates to normalized vision coordinates has a determinant of about 5e-07.
    func colinear(tolerance: Float = 1e-20) -> Bool {
        let m = toMatrix()
        return abs(m.determinant) < tolerance
    }
    
    /// Returns a 3x3 matrix with triangle vertices in columns.
    /// | p1.x    p2.x      p3.x |
    /// | p1.y    p2.y      p3.y |
    /// |   1       1            1    |
    func toMatrix() -> float3x3 {
        float3x3(point1.toVector3(), point2.toVector3(), point3.toVector3())
    }
    
    /// Returns a Triangle from a 3x3 matrix that presents homogeneous coordinates (xZ, yZ, Z) in columns.
    /// Throws a GeometryError.matrixInvalid exception if an element of the final row is zero
    /// | p1.x    p2.x   p3.x |
    /// | p1.y    p2.y   p3.y |  :  error thrown if p1.z, p2.z, and/or p3.z is zero
    /// | p1.z    p2.z   p3.z |
    static func fromMatrix(_ m: float3x3) throws -> Triangle {
        let c1 = m.columns.0
        let c2 = m.columns.1
        let c3 = m.columns.2
        
        if c1.z.isZero || c2.z.isZero || c3.z.isZero {
            let f = NumberFormatter()
            let s = "At least one element is zero in the last row of a triangle vertex matrix: "
                + "|\(f.string(c1.z, 6))  \(f.string(c2.z, 6))   \(f.string(c3.z, 6))|"
            throw GeometryError.matrixInvalid(description: s)
        }
        
        let p1 = c1.toVector2()
        let p2 = c2.toVector2()
        let p3 = c3.toVector2()
        return Triangle(p1, p2, p3)
    }
    
    /// Generates a random triangle with points in the range (-magnitude, -magniture) to (+magnitude, +magnitude).
    /// Handy for testing affine transforms functions.
    static func randomTriangle(_ magnitude: Float = 10) -> Triangle {
        let randomPoint = { (mag: Float) -> simd_float2 in
            simd_float2(Float.random(in: -magnitude...magnitude), Float.random(in: -magnitude...magnitude))
        }
        return Triangle(randomPoint(magnitude), randomPoint(magnitude), randomPoint(magnitude))
    }
}

struct Transform {
    /// 3x3 transform to map the 'from' point to the 't' point
    /// |  1  0  (to - from).x |
    /// |  0  1  (to - from).y |
    /// |  0  0                  1 |
    static func translation(from: simd_float2, to: simd_float2) -> float3x3 {
        let delta = to - from
        var f = float3x3(1)
        f[2,0] = delta.x
        f[2,1] = delta.y
        return f
    }
    
    /// Finds the affine transform (translation, rotation, scale, ...) from one triangle to another.
    /// A triangle is understood to be a set of three non-colinear points.
    /// See https://rethunk.medium.com/finding-an-affine-transform-the-traditional-way-with-three-2d-point-correspondences-in-swift-7c602682bfbc
    static func affine(from: Triangle, to: Triangle) -> float3x3? {
        // nice description of the meaning of determinant being zero:
        // https://math.stackexchange.com/questions/355644/what-does-it-mean-to-have-a-determinant-equal-to-zero
        // and from that page, a link to a GREAT video about determinants:
        // https://www.youtube.com/watch?v=Ip3X9LOh2dk
        
        let fc = from.colinear()
        let tc = to.colinear()
        
        // Check the (near-)colinearity condition of both triangles. Name the colinearity explicitly.
        if fc || tc {
            //TODO throw an error, but returning nil is sufficient for now
            let sf = "'From' triangle is \(fc ? "COLINEAR" : "okay")."
            let st = "'To' triangle is \(tc ? "COLINEAR" : "okay")."
            print("Can not calculate affine transform. \(sf) \(st)")
            return nil
        }
        
        // following example from https://stackoverflow.com/questions/18844000/transfer-coordinates-from-one-triangle-to-another-triangle
        // M * A = B
        // M = B * Inv(A)
        let A = from.toMatrix()
        let invA = A.inverse
        
        if invA.determinant.isNaN {
            print("Can not calculate affine transform. Determinant of inverse of 'From' triangle is zero.")
            return nil
        }
        
        let B = to.toMatrix()
        let M = B * invA
        
        return M
    }
}

/// The direction of a coordinate axis.
/// Given that coordinates within the device / image frame are positive,
/// we need only know the Corner and Direction of the X-axis to determine
/// whether the X-axis points left or right. Given the Corner and Direction
/// of the X-axis, we also know the direction of the Y-axis.
enum Alignment: String {
    case Horizontal = "Horizontal"
    case Vertical = "Vertical"
    
    /// The other direction: if self is Horizontal, then the complement is Vertical.
    /// If self is Vertical, then Horizontal.
    var complement: Alignment {
        switch self {
        case .Horizontal:
            return .Vertical
        case .Vertical:
            return .Horizontal
        }
    }
}

/// The corner of a rectangle with edges aligned horizontally and vertically.
enum Corner: String {
    case BottomLeft = "Bottom Left"
    case BottomRight = "Bottom Right"
    case TopLeft = "Top Left"
    case TopRight = "Top Right"
}

/// One of four directions: Down, Left, Right, Up.
enum Direction: String {
    case Down = "Down"
    case Left = "Left"
    case Right = "Right"
    case Up = "Up"
    
    var complement: Direction {
        switch self {
        case .Down:
            return .Up
        case .Left:
            return .Right
        case .Right:
            return .Left
        case .Up:
            return .Down
        }
    }
}

/// Minimalist Error subtype for coordinate frame functions that may throw errors.
enum FrameError: Error {
    case axesNotOrthogonal
    case cornerNotDetermined
}

/// An error for various computations using points, matrices, and so on.
enum GeometryError: Error {
    /// Points are unexpectedly or undesirably colinear.
    case colinearPoints(description: String)

    /// Attempted division by zero in some calculation
    case divideByZero(description: String)

    /// The determinant of a matrix is zero, and shouldn't be.
    case matrixDeterminantIsZero(description: String)

    /// Matrix elements do not conform to expectations.
    /// For example, if a 3x3 matrix contains the points of a triangle in
    /// homogeneous coordinates, no element in the final row may be zero.
    /// | x1  x2  x3 |
    /// | y1  y2  y3 |  --> invalid because the final row for point 2 has a zero value
    /// |   1   0    3 |
    case matrixInvalid(description: String)

    /// Roll your own.
    case otherError(error: Error)
}

// Convenience functions for pretty-ish printing. Typically used for string interpolation in calls to print().
extension NumberFormatter {
    func string(_ m: simd_float2, _ digits: Int) -> String {
        "[\(string(m.x, digits)), \(string(m.y, digits))]"
    }
    
    func string(_ m: simd_float3, _ digits: Int) -> String {
        "[\(string(m.x, digits)), \(string(m.y, digits)), \(string(m.z, digits))]"
    }

    func string(_ m: float3x3, _ digits: Int) -> String {
        //SIMD: column, row (like x,y)

        "\(string(m[0][0], digits))  \(string(m[1][0], digits))  \(string(m[2][0], digits))"
        + "\n\(string(m[0][1], digits))  \(string(m[1][1], digits))  \(string(m[2][1], digits))"
        + "\n\(string(m[0][2], digits))  \(string(m[1][2], digits))  \(string(m[2][2], digits))"
    }
    
    // Triangle is a CustomStringConvertible, but here you can specify the number of digits after the decimal.
    func string(_ t: Triangle, _ digits: Int) -> String {
        "\(string(t.point1, digits)), \(string(t.point2, digits)), \(string(t.point3, digits))"
    }
    
    func string(_ value: Float, _ digits: Int, failText: String = "[?]") -> String {
        minimumFractionDigits = max(0, digits)
        maximumFractionDigits = minimumFractionDigits
        
        guard let s = string(from: NSNumber(value: value)) else {
            return failText
        }
        
        return s
    }
    
    func string(_ value: CGFloat, _ digits: Int, failText: String = "[?]") -> String {
        minimumFractionDigits = max(0, digits)
        maximumFractionDigits = minimumFractionDigits
        
        guard let s = string(from: NSNumber(value: Double(value))) else {
            return failText
        }
        
        return s
    }
    
    func string(_ point: CGPoint, _ digits: Int = 1, failText: String = "[?]") -> String {
        let sx = string(point.x, digits, failText: failText)
        let sy = string(point.y, digits, failText: failText)
        return "(\(sx), \(sy))"
    }
}

// Conversions between 2D points and 1x3 homogeneous coordinates.
extension simd_float2 {
    /// Returns (inf, inf) if v.z == 0
    static func fromVector3(_ v: simd_float3) -> simd_float2 {
        simd_float2(v.x / v.z, v.y / v.z)
    }
    
    /// Returns (x, y, 1)
    func toVector3() -> simd_float3 {
        simd_float3(self.x, self.y, 1)
    }
}

// Conversions between 1x3 homogeneous coordinates and 2D points.
extension simd_float3 {
    /// Returns (x,y,1)
    static func fromVector2(_ v: simd_float2) -> simd_float3 {
        simd_float3(v.x, v.y, 1)
    }
    
    /// Returns (inf,inf) if v.z == 0
    func toVector2() -> simd_float2 {
        simd_float2(self.x / self.z, self.y / self.z)
    }
}

extension CGAffineTransform {
    /// Generates a 3x3 matrix from the CGAffineTransform
    /// The 3x3 matrix is transposed relative to the CGAffineTransform:
    /// CGAffineTransform:
    /// | a   b   0 |
    /// | c   d   0 |
    /// | tx  ty  1 |
    ///
    /// 3x3 matrix
    /// | a  c  tx |
    /// | b  d  ty |
    /// | 0  0   1 |
    func toMatrix3x3() -> float3x3 {
        return float3x3(
            SIMD3<Float>(Float(self.a), Float(self.b), Float(0)),
            SIMD3<Float>(Float(self.c), Float(self.d), Float(0)),
            SIMD3<Float>(Float(self.tx), Float(self.ty), Float(1)))
    }
    
    /// Generates a CGAffineTransform from a 3x3 matrix
    /// The 3x3 matrix is transposed relative to the CGAffineTransform:
    /// CGAffineTransform:
    /// | a   b   0 |
    /// | c   d   0 |
    /// | tx  ty  1 |
    ///
    /// 3x3 matrix
    /// | a  c  tx |
    /// | b  d  ty |
    /// | 0  0   1 |
    static func fromMatrix3x3(_ m: float3x3) -> CGAffineTransform {
        if !m[0][2].isZero {
            print("Non-affine matrix element [0][2] is non-zero")
        }
        
        if !m[1][2].isZero {
            print("Non-affine matrix element [1][2] is non-zero")
        }

        return CGAffineTransform(
            a: CGFloat(m[0][0]),
            b: CGFloat(m[0][1]),
            c: CGFloat(m[1][0]),
            d: CGFloat(m[1][1]),
            tx: CGFloat(m[2][0]),
            ty: CGFloat(m[2][1]))
    }
}

// Conversions to/from CGPoint for use with CGImage and SIMD matrix operations.
extension CGPoint {
    /// Applies a 3x3 matrix to the CGPoint.
    /// Converts from CGPoint to 1x3 homogeneous coordinate,
    /// applies the transform, then converts back to CGPoint.
    /// The 3x3 matrix, such as that generated by perspectiveTransform(),
    /// will be transposed relative to CGAffineTransform, which
    /// has translation components tx and ty in the bottom row.
    func applying(_ matrix: float3x3) -> CGPoint {
        let v = self.vector3
        let t = matrix * v
        return CGPoint.fromVector3(t)
    }
    
    /// A 1x2 vector of the point: (x, y)
    var vector2: simd_float2 {
        simd_float2(Float(self.x), Float(self.y))
    }
    
    /// A 1x3 vector of the point (x, y, 1)
    var vector3: simd_float3 {
        simd_float3(Float(self.x), Float(self.y), Float(1))
    }
    
    /// Returns a point (v.x, v.y)
    static func fromVector2(_ v: simd_float2) -> CGPoint {
        CGPoint(x: CGFloat(v.x), y: CGFloat(v.y))
    }
    
    /// Returns a point (x, y) = (v.x / v.z, v.y / v.z)
    /// Returns {x +∞, y +∞} if v.z == 0
    static func fromVector3(_ v: simd_float3) -> CGPoint {
        CGPoint(x: CGFloat(v.x / v.z), y: CGFloat(v.y / v.z))
    }
    
    /// Returns a (CGPoint) -> CGPoint function for a 3x3 transform
    static func converter(_ transform: float3x3) -> (CGPoint) -> CGPoint {
        let function = { (cg: CGPoint) -> CGPoint in
            let p3 = cg.vector3
            let q3 = transform * p3
            return CGPoint.fromVector3(q3)
        }
        return function
    }
}

/* TEST CODE */
/// Find the transform between two frames and print info to the console.
func testTransform(from: ImageFrame, fromName: String, to: ImageFrame, toName: String) {
    print()
    print("**********************************")
    print("from '\(fromName)' [\(from)]")
    print("to '\(toName)' [\(to)]")

    guard let t = ImageFrame.transform(from: from, to: to) else {
        print()
        print("Error: could not find transform between image frames.")
        return
    }

    let n = NumberFormatter()
    print()
    
    var s = "\(fromName) --> \(toName)"
    
    if from == to {
        s += "  [should be identity matrix -- all 1.0s along diagonal]"
    }
    
    print("\(s)")
    print("\(n.string(t, 2))")
    print()
    
    let cg = CGAffineTransform.fromMatrix3x3(t)
    print(cg)
    
    //convert a point 1/2 the width and 1/3 the height of the "from" frame
    let p = CGPoint(x: CGFloat(from.size.x) / 2.0, y: CGFloat(from.size.y) / 3.0)
    let qt = p.applying(t)
    let qcg = p.applying(cg)
    
    print()
    print("from \(n.string(p, 2)) -> \(n.string(qt, 2)) using CGPoint.applying(float3x3)")
    print("from \(n.string(p, 2)) -> \(n.string(qcg, 2)) using CGPoint.applying(CGAffineTransform)")
}

public func testFrames() {
    let normalizedSize = ImageFrame.normalizedSize
    let uiSize = simd_float2(375, 667)
    let imageSize = simd_float2(1080,1920)
    
    let frameOCR = ImageFrame(origin: .BottomLeft, xAlignment: .Horizontal, size: normalizedSize)
    let frameUI = ImageFrame(origin: .TopLeft, xAlignment: .Horizontal, size: uiSize)
    let frameImage = ImageFrame(origin: .TopLeft, xAlignment: .Horizontal, size: imageSize)
    let frameQR = ImageFrame(origin: .TopRight, xAlignment: .Vertical, size: normalizedSize)
    
    var frames: [(frame: ImageFrame, name: String)] = []
    frames.append((frame: frameOCR, name: "OCR"))
    frames.append((frame: frameUI, name: "UI"))
    frames.append((frame: frameImage, name: "Image"))
    frames.append((frame: frameQR, name: "QR Code"))
    
    //transform from each frame to every other frame (including itself)
    for f in frames {
        for g in frames {
            testTransform(from: f.frame, fromName: f.name, to: g.frame, toName: g.name)
        }
    }
}
