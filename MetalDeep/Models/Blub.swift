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

class Blub: Node {
    init(name: String, textureName: String, device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) {
        let textureLoader = MTKTextureLoader(device: device)
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        
        let blubMaterial = Material()
        let blubBaseColorTexture = try? textureLoader.newTexture(name: "blub_baseColor",
                                                                 scaleFactor: 1.0,
                                                                 bundle: nil,
                                                                 options: options)
        blubMaterial.baseColorTexture = blubBaseColorTexture
        blubMaterial.specularPower = 40
        blubMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
         
        let blubURL = Bundle.main.url(forResource: "blub", withExtension: "obj")!
        let blubAsset = MDLAsset(url: blubURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        let blubMesh = try! MTKMesh.newMeshes(asset: blubAsset, device: device).metalKitMeshes.first!
        
        super.init(name: name)
        
        material = blubMaterial
        material.specularPower = 1000
        mesh = blubMesh
    }
}
