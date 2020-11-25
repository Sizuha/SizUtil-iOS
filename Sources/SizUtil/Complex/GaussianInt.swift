//
//  GaussianInt.swift
//  Complex
//
//  Created by Dan Kogai on 2018/05/25.
//
/*
 https://github.com/dankogai/swift-complex
 
 The MIT License (MIT)

 Copyright (c) 2014-2016 Dan Kogai

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

public protocol ComplexInt : ComplexNumeric & CustomStringConvertible
    where Element: SignedInteger {
}

extension ComplexInt {
    /// description -- conforms to Printable
    public var description:String {
        let sig = imag < 0 ? "-" : "+"
        return "(\(real)\(sig)\(imag.magnitude).i)"
    }
    /// /
    public static func /(_ lhs:Self, _ rhs:Element)->Self {
        return Self(lhs.real / rhs, lhs.imag / rhs)
    }
    public static func /(_ lhs:Self, _ rhs:Self)->Self {
        return lhs * rhs.conj / rhs.norm
    }
    public static func /(_ lhs:Element, _ rhs:Self)->Self {
        return Self(lhs, 0) / rhs
    }
    public static func /=(_ lhs:inout Self, _ rhs:Self) {
        lhs = lhs / rhs
    }
    public static func /=(_ lhs:inout Self, _ rhs:Element) {
        lhs = lhs / rhs
    }
}

public typealias GaussianIntElement = SignedInteger

public struct GaussianInt<I:GaussianIntElement> : ComplexInt {
    public typealias NumericType = I
    public var (real, imag):(I, I)
    public init(real r:I, imag i:I) {
        (real, imag) = (r, i)
    }
}

extension GaussianInt : Codable where Element: Codable {
    public enum CodingKeys : String, CodingKey {
        public typealias RawValue = String
        case real, imag
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.real = try values.decode(Element.self, forKey: .real)
        self.imag = try values.decode(Element.self, forKey: .imag)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.real, forKey: .real)
        try container.encode(self.imag, forKey: .imag)
    }
}

extension SignedInteger where Self:Codable {
    public var i:GaussianInt<Self> {
        return GaussianInt(0, self)
    }
}
