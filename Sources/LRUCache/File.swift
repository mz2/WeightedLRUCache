//
//  File.swift
//  
//
//  Created by Matias Piipari on 10/05/2020.
//

import Foundation

protocol Weighted {
    var weight: Int { get }
}

extension Int: Weighted {
    var weight: Int {
        return self
    }
}
