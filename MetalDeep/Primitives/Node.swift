//
//  Node.swift
//  MetalDeep
//
//  Created by Jacob Sansbury on 2/6/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//

import Foundation
import MetalKit

class Node {
    var name: String
    weak var parent: Node?
    var children = [Node]()
    var modelMatrix = matrix_identity_float4x4
    var mesh: MTKMesh?
    var material = Material()
 
    init(name: String) {
        self.name = name
    }
    
    func add(node: Node) {
        children.append(node)
    }
    
    func nodeNamedRecursive(_ name: String) -> Node? {
        for node in children {
            if node.name == name {
                return node
            } else if let matchingGrandchild = node.nodeNamedRecursive(name) {
                return matchingGrandchild
            }
        }
        return nil
    }
    
    func update(time: Float) {
        for node in children {
            node.update(time: time)
        }
    }
}
