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

struct Light {
    var worldPosition = SIMD3<Float>(0, 0, 0)
    var color = SIMD3<Float>(0, 0, 0)
}

class Material {
    var specularColor = SIMD3<Float>(1, 1, 1)
    var specularPower = Float(1)
    var baseColorTexture: MTLTexture?
}

struct FragmentUniforms {
    var cameraWorldPosition = SIMD3<Float>(0, 0, 0)
    var ambientLightColor = SIMD3<Float>(0, 0, 0)
    var specularColor = SIMD3<Float>(1, 1, 1)
    var specularPower = Float(1)
    var light0 = Light()
    var light1 = Light()
    var light2 = Light()
}

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
    
}

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
}
