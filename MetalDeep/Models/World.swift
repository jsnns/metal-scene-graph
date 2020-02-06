//
//  FullScene.swift
//  MetalDeep
//
//  Created by Jacob Sansbury on 2/6/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//

import Foundation
import MetalKit

class World {
    let textureLoader: MTKTextureLoader!
    let bufferAllocator: MTKMeshBufferAllocator!
    let vertexDescriptor: MDLVertexDescriptor!
    let device: MTLDevice!
    let scene = Scene()
    let fishCount = 200
    
    init(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) {
        textureLoader = MTKTextureLoader(device: device)
        bufferAllocator = MTKMeshBufferAllocator(device: device)
        self.vertexDescriptor = vertexDescriptor
        self.device = device
        
        self.buildScene()
        self.createLights()
    }
    
    func createLights() {
        scene.ambientLightColor = SIMD3<Float>(0.01, 0.01, 0.01)
        let light0 = Light(worldPosition: SIMD3<Float>( 2,  2, 2), color: SIMD3<Float>(1, 0.75, 0.75))
        let light1 = Light(worldPosition: SIMD3<Float>(-2,  2, 2), color: SIMD3<Float>(1, 1, 1))
        let light2 = Light(worldPosition: SIMD3<Float>( 0, -2, 2), color: SIMD3<Float>(1, 1, 1))
        scene.lights = [ light0, light1, light2 ]
    }
    
    func buildScene() {
        let bob = Duck(name: "Bob", textureName: "bob_baseColor", device: device, vertexDescriptor: vertexDescriptor)
        bob.modelMatrix = float4x4(translationBy: SIMD3<Float>(-0.5, 0, 0))
        scene.add(node: bob)
        
        let rose = Duck(name: "Rose", textureName: "rose_baseColor", device: device, vertexDescriptor: vertexDescriptor)
        rose.modelMatrix = float4x4(translationBy: SIMD3<Float>(0.5, 0, 0))
        scene.add(node: rose)
        
        let stillBlub = Blub(name: "Still", textureName: "blub_baseColor", device: device, vertexDescriptor: vertexDescriptor)
        stillBlub.modelMatrix = float4x4(translationBy: SIMD3<Float>(0, 0.5, 0)) * float4x4(rotationAbout: SIMD3<Float>(1, -2, 0), by: Float.pi * (45/360))
        scene.add(node: stillBlub)

        
        for i in 1...fishCount {
            let blub = Blub(name: "Blub \(i)", textureName: "blub_baseColor", device: device, vertexDescriptor: vertexDescriptor)
            
            if (i % 2 == 0) {
                bob.add(node: blub)
            } else {
                rose.add(node: blub)
            }
        }
    }
    
    func update(time: Float) {
        scene.rootNode.modelMatrix = float4x4(rotationAbout: SIMD3<Float>(0, 1, 0), by: Float.pi * 0.35) * float4x4(translationBy: SIMD3<Float>(time * -0.1, 1, 0))
        
        /// Update blub's position
        let blubBaseTransform = float4x4(rotationAbout: SIMD3<Float>(0, 0, 1), by: -.pi / 2) *
            float4x4(scaleBy: 0.35) *
            float4x4(rotationAbout: SIMD3<Float>(0, 1, 0), by: -.pi / 2)
        
        for i in 1...fishCount {
            if let blub = scene.nodeNamed("Blub \(i)") {
                let pivotPosition = SIMD3<Float>(0.9, 0, 0)
                let rotationOffset = SIMD3<Float>(0.9, 0, 0)
                let rotationSpeed = Float(0.3)
                let rotationAngle = 2 * Float.pi * Float(rotationSpeed * time) + (2 * Float.pi / Float(fishCount) * Float(i - 1))
                let horizontalAngle = 2 * .pi / Float(fishCount) * Float(i - 1)
                blub.modelMatrix = float4x4(rotationAbout: SIMD3<Float>(0, 1, 0), by: horizontalAngle) *
                    float4x4(translationBy: rotationOffset) *
                    float4x4(rotationAbout: SIMD3<Float>(0, 0, 1), by: rotationAngle) *
                    float4x4(translationBy: pivotPosition) *
                blubBaseTransform
            }
        }
        
        scene.update(time: time)
    }
}

