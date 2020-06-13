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

struct WeightedValue<T>: Weighted {
    let weight: UInt
    let value: T
}
