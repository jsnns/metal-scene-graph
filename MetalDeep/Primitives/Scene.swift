//
//  Scene.swift
//  MeatlDeep
//
//  Created by Jacob Sansbury on 2/5/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//
import simd
import Metal
import MetalKit

class Scene {
    var rootNode = Node(name: "Root")
    var ambientLightColor = SIMD3<Float>(0, 0, 0)
    var lights = [Light]()
    
    func nodeNamed(_ name: String) -> Node? {
        if rootNode.name == name {
            return rootNode
        } else {
            return rootNode.nodeNamedRecursive(name)
        }
    }
    
    func add(node: Node) {
        rootNode.add(node: node)
    }
    
    func update(time: Float) {
        rootNode.update(time: time)
    }
}
