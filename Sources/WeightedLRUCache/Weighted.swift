//
//  File.swift
//
//
//  Created by Matias Piipari on 10/05/2020.
//

import Foundation

public protocol Weighted {
    var weight: UInt { get }
}

public struct WeightedValue<T>: Weighted {
    public let weight: UInt
    public let value: T
}
