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

class Duck: Node {
    init(name: String, textureName: String, device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) {
        let textureLoader = MTKTextureLoader(device: device)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]

        let duckURL = Bundle.main.url(forResource: "bob", withExtension: "obj")!
        let duckAsset = MDLAsset(url: duckURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let duckMaterial = Material()
        let duckBaseColorTexture = try? textureLoader.newTexture(name: textureName,
                                                           scaleFactor: 1.0,
                                                           bundle: nil,
                                                           options: options)
        duckMaterial.baseColorTexture = duckBaseColorTexture
        duckMaterial.specularPower = 200
        duckMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
        
        super.init(name: name)
        
        self.material = duckMaterial
        self.mesh = try! MTKMesh.newMeshes(asset: duckAsset, device: device).metalKitMeshes.first!
    }
    
    
    override func update(time: Float) {
        modelMatrix = modelMatrix * float4x4(translationBy: SIMD3<Float>(0, 0.001 * sin(time * 5), 0))
        
        super.update(time: time)
    }
}
