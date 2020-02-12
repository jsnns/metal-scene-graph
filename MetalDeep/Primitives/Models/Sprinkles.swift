//
//  Duck.swift
//  MetalDeep
//
//  Created by Jacob Sansbury on 2/6/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//

import Foundation
import MetalKit
import ModelIO

class Sprinkles: Node {
    init(name: String, device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) {
        super.init(name: name)
        let textureLoader = MTKTextureLoader(device: device)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]

        let nut = Node(name: "Nut")
        
        let nutUrl = Bundle.main.url(forResource: "nut", withExtension: "obj")!
        let nutAsset = MDLAsset(url: nutUrl, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let nutMaterial = Material()
        nutMaterial.specularPower = 200
        nutMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
        let nutBaseColorTexture = try? textureLoader.newTexture(name: "nut_baseColor",
                                                           scaleFactor: 1.0,
                                                           bundle: nil,
                                                           options: options)
        nutMaterial.baseColorTexture = nutBaseColorTexture
        nut.mesh = try! MTKMesh.newMeshes(asset: nutAsset, device: device).metalKitMeshes.first!
        nut.material = nutMaterial
        self.add(node: nut)
        
        let sprinkels = Node(name: "SprinklesTop")
        
        let sprinklesUrl = Bundle.main.url(forResource: "sprinkles", withExtension: "obj")!
        let sprinkelsAsset = MDLAsset(url: sprinklesUrl, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let sprinkelsMaterial = Material()
        sprinkelsMaterial.specularPower = 200
        sprinkelsMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
        let sprinklesBaseColorTexture = try? textureLoader.newTexture(name: "sprinkles_baseColor",
                                                           scaleFactor: 1.0,
                                                           bundle: nil,
                                                           options: options)
        sprinkelsMaterial.baseColorTexture = sprinklesBaseColorTexture
        sprinkels.mesh = try! MTKMesh.newMeshes(asset: sprinkelsAsset, device: device).metalKitMeshes.first!
        sprinkels.material = sprinkelsMaterial
        self.add(node: sprinkels)
    }
}
