//
//  SizData.swift
//  
//
//  Created by Sizuha on 2020/10/22.
//

import Foundation


public extension Array {
    
    subscript(at index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Arrayから、where条件と一致する要素を探して、その要素のIndexだけを収集する
    /// - Parameter where: 条件
    /// - Returns: Array of Index
    func indices(where filter: (_ data: Element, _ index: Int)->Bool) -> [Int] {
        var ix = 0
        var result = [Int]()
        result.reserveCapacity(self.count/2)
        
        for e in self {
            if filter(e,ix) { result.append(ix) }
            ix += 1
        }
        return result
    }
    
    func with(_ array: Array, action: (Element, Element)->Element) throws -> [Element] {
        guard self.count == array.count else {
            throw NSError(domain: "Two Array must be same length!", code: 0, userInfo: nil)
        }
        
        return (0..<self.count).map { i in
            action(self[i], array[i])
        }
    }
    
}

public func slice2d(array: [[Double]], rangeY: Range<Int>, rangeX: Range<Int>) -> [[Double]] {
    var result = [[Double]]()
    result.reserveCapacity(rangeY.count)
    
    for i_y in 0..<array.count {
        guard rangeY.contains(i_y) else { continue }
        
        let arrX = array[i_y]
        
        var arr_buffer = [Double]()
        arr_buffer.reserveCapacity(rangeX.count)
        
        for i_x in 0..<arrX.count {
            guard rangeX.contains(i_x) else { continue }
            
            let val = arrX[i_x]
            arr_buffer.append(val)
        }

        result.append(arr_buffer)
    }
    
    return result
}

public func fill(to array: inout [[Double]], rangeY: Range<Int>? = nil, rangeX: Range<Int>? = nil, value: Double) {
    for i_y in 0..<array.count {
        guard rangeY?.contains(i_y) ?? true else { continue }
        
        let arrX = array[i_y]
        for i_x in 0..<arrX.count {
            guard rangeX?.contains(i_x) ?? true else { continue }
            array[i_y][i_x] = value
        }
    }
}

public class Rolling {
    private let contents: [Double]
    private var offset = 0
    private var center = false
    
    init(contents: [Double], offset: Int, center: Bool = false) {
        self.contents = contents
        self.offset = offset
        self.center = center
    }
    
    func excute(_ exec: ([Double])->Double) ->[Double] {
        var result = [Double](repeating: Double.nan, count: self.contents.count)
        let addIdx = self.offset % 2 == 1 ? 0 : 1 // for Center is True
        
        var tempArr = [Double]()
        tempArr.reserveCapacity(self.offset)
        for i in 0..<self.contents.count {
            tempArr.append(self.contents[i])
            
            guard i >= self.offset-1 else {
                continue
            }
            
            let value = exec(tempArr)
            let outputIndex: Int
            if self.center {
                let from_i = i - self.offset + 1
                outputIndex = (from_i + i)/2 + addIdx
            }
            else {
                outputIndex = i
            }
            
            result[outputIndex] = value
            tempArr.removeFirst()
        }
        
        return result
    }
}

public extension Range {
    
    static func create(from: Int, length: Int) -> Range<Int> {
        from..<(from + length)
    }
    
}

prefix operator ?=

public extension String {
    init(timeInterval: TimeInterval, format: String = "%02d:%02d:%02d") {
        let seconds = Int(timeInterval)
        let h = seconds/60/60
        let m = (seconds/60) % 60
        let s = seconds % 60
        self.init(format: format, h, m, s)
    }
    
    func localized(bundle: Bundle = .main, tableName: String = "Localizable", ifNotExist: String? = nil) -> String {
        let defaultValue = ifNotExist ?? "{\(self)}"
        return NSLocalizedString(self, tableName: tableName, value: defaultValue, comment: "")
    }
    
    func asLinkText() -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        let range = NSRange(location: 0, length: self.count)
        
        attributedString.addAttribute(NSAttributedString.Key.link, value: link, range: range)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: range)
        
        return attributedString
    }
    
    func subStr(from: Int, length: Int) -> String {
        let to = self.index(self.startIndex, offsetBy: from + length)
        let from = self.index(self.startIndex, offsetBy: from)
        return String(self[from..<to])
    }
    
    func subStr(from: Int) -> String {
        let to = self.endIndex
        let from = self.index(self.startIndex, offsetBy: from)
        return String(self[from..<to])
    }
    
    func getNSRange() -> NSRange {
        return NSRange(location: 0, length: self.count)
    }
    
    var asPattern: NSRegularExpression? {
        try? NSRegularExpression(pattern: self, options: [])
    }
    
    static prefix func ?= (pattern: String) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern, options: [])
    }
    static func ~= (left: String, right: NSRegularExpression?) -> Bool {
        return left.isMatch(right)
    }
    static func ~= (left: NSRegularExpression?, right: String) -> Bool {
        return right.isMatch(left)
    }

    func isMatch(_ regex: NSRegularExpression?) -> Bool {
        return regex?.numberOfMatches(in: self, options: [], range: getNSRange()) ?? 0 > 0
    }
    func isNotMatch(_ regex: NSRegularExpression?) -> Bool {
        return !isMatch(regex)
    }
    
    var deletingPathExtension: String {
        NSString(string: self).deletingPathExtension
    }
}

public extension NSRegularExpression {
    func isMatch(_ string: String) -> Bool {
        return numberOfMatches(in: string, options: [], range: string.getNSRange()) > 0
    }
    func isNotMatch(_ string: String) -> Bool {
        return !isMatch(string)
    }
}

// MARK: - DSP 関連
// 後ほど、別のPackageに分離

open class SizDsp {

    public enum WindowFunc {
        case Hamming
        case Hanning
        case Blackman
        case Rectangular
    }
        
    public static func Windowing(_ data: [Double], _ windowFunc: WindowFunc) -> [Double] {
        let size = data.count;
        var windata = [Double](repeating: 0, count: size)
        
        for i in 0..<size {
            var winValue: Double = 0.0;
            // 各々の窓関数
            switch windowFunc {
            case .Hamming:
                winValue =
                    0.54
                    - 0.46 * cos(2.0 * Double.pi * Double(i) / Double(size - 1))
                
            case .Hanning:
                winValue =
                    0.5
                    - 0.5 * cos(2.0 * Double.pi * Double(i) / Double(size - 1))
                
            case .Blackman:
                winValue =
                    0.42 - 0.5 * cos(2 * Double.pi * Double(i) / Double(size - 1))
                    + 0.08 * cos(4 * Double.pi * Double(i) / Double(size - 1))

            case .Rectangular:
                winValue = 1.0;
            }
            
            // 窓関数を掛け算
            windata[i] = data[i] * winValue;
        }
        return windata;
    }

    public static func getWindow(_ N: Int, _ windowFunc: WindowFunc) -> [Double] {
        let ones = [Double](repeating: 1.0, count: N)
        let result = Self.Windowing(ones, windowFunc)
        return result
    }

    public static func dft(x: [Double]) -> ([Double],[Double]) {
        let N = x.count
        var Xre: [Double] = Array(repeating:0, count:N)
        var Xim: [Double] = Array(repeating:0, count:N)

        let f = 2.0 * Double.pi / Double(N)

        for k in 0..<N {
            let kf = Double(k) * f
            let (cosa, sina) = (cos(kf), sin(kf))
            var (cosq, sinq) = (1.0, 0.0)

            for n in 0..<N {
                Xre[k] += x[n] * cosq
                Xim[k] -= x[n] * sinq
                (cosq, sinq) = (cosq * cosa - sinq * sina, sinq * cosa + cosq * sina)
            }
        }
        
        return (Xre, Xim)
    }

    /// https://github.com/scipy/scipy/blob/master/scipy/signal/_peak_finding.py
    public static func findPeaks(_ x: [Double]) -> [Int] {
        // Preallocate, there can't be more maxima than half the size of `x`
        var midpoints = [Int](repeating: 0, count: x.count/2)
        var left_edges = [Int](repeating: 0, count: x.count/2)
        var right_edges = [Int](repeating: 0, count: x.count/2)
        var m = 0 // Pointer to the end of valid area in allocated arrays
        
        var i = 1 // Pointer to current sample, first one can't be maxima
        let i_max = x.count - 1 // Last sample can't be maxima
        while i < i_max {
            // Test if previous sample is smaller
            if x[i-1] < x[i] {
                var i_ahead = i + 1 // Index to look ahead of current sample
                
                // Find next sample that is unequal to x[i]
                while i_ahead < i_max && x[i_ahead] == x[i] {
                    i_ahead += 1
                }
                
                // Maxima is found if next unequal sample is smaller than x[i]
                if x[i_ahead] < x[i] {
                    left_edges[m] = i
                    right_edges[m] = i_ahead - 1
                    midpoints[m] = (left_edges[m] + right_edges[m]) / 2
                    m += 1
                    // Skip samples that can't be maximum
                    i = i_ahead
                }
            }
            i += 1
        }
        
        // Keep only valid part of array memory.
        midpoints = midpoints[0..<m].map { $0 }
        //left_edges = left_edges[0..<m].map { $0 }
        //right_edges = right_edges[0..<m].map { $0 }
        
        return midpoints
    }

}
