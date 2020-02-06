//
//  Render.swift
//  MeatlDeep
//
//  Created by Jacob Sansbury on 2/5/20.
//  Copyright © 2020 Jacob Sansbury. All rights reserved.
//

import Foundation
import MetalKit
import ModelIO
import simd

struct VertexUniforms {
    var viewProjectionMatrix: float4x4
    var modelMatrix: float4x4
    var normalMatrix: float3x3
}

class Render: NSObject, MTKViewDelegate {
    
    let mtkView: MTKView!
    let device: MTLDevice!
    var vertexDescriptor: MDLVertexDescriptor!
    
    var meshes: [MTKMesh] = []
    let commandQueue: MTLCommandQueue
    
    var time: Float = 0
    
    let samplerState: MTLSamplerState
    var renderPipeline: MTLRenderPipelineState!
    let depthStencilState: MTLDepthStencilState
    
    var baseColorTexture: MTLTexture?
    
    let scene: Scene

    var cameraWorldPosition = SIMD3<Float>(0, 0, 0)
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
    init(view: MTKView, device: MTLDevice) {
        self.mtkView = view
        self.device = device
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        self.commandQueue = device.makeCommandQueue()!
        self.depthStencilState = Render.buildDepthStencilState(device: device)
        self.samplerState = Render.buildSamplerState(device: device)
        self.vertexDescriptor = Render.buildVertexDescriptor()
        self.scene = Render.buildScene(device: device, vertexDescriptor: vertexDescriptor)
        
        super.init()
        
        buildPipeline()
    }
    
    func update(_ view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
     
        cameraWorldPosition = SIMD3<Float>(0, 1.2, 3)
        viewMatrix = float4x4(translationBy: -cameraWorldPosition) * float4x4(scaleBy: 1)
     
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
     
        scene.rootNode.modelMatrix = float4x4(rotationAbout: SIMD3<Float>(0, 1, 0), by: Float.pi * 0.35) * float4x4(translationBy: SIMD3<Float>(time * -0.1, 1, 0))
        
        /// Update bob's position
        if let bob = scene.nodeNamed("Bob") {
            bob.modelMatrix = float4x4(translationBy: SIMD3<Float>(0.5, 0.015 * sin(time * 5), 0))
        }
        
        /// Update rose's position
        if let rose = scene.nodeNamed("Rose") {
            rose.modelMatrix = float4x4(translationBy: SIMD3<Float>(-0.5, 0.015 * sin((time + 1) * 5), 0))
        }
        
        /// Set still blub's position
        if let stillBlub = scene.nodeNamed("Still") {
            stillBlub.modelMatrix = float4x4(translationBy: SIMD3<Float>(0, 0.5, 0)) * float4x4(rotationAbout: SIMD3<Float>(1, -2, 0), by: Float.pi * (45/360))
        }
        
        /// Update blub's position
        let blubBaseTransform = float4x4(rotationAbout: SIMD3<Float>(0, 0, 1), by: -.pi / 2) *
                                float4x4(scaleBy: 0.35) *
                                float4x4(rotationAbout: SIMD3<Float>(0, 1, 0), by: -.pi / 2)
         
        let fishCount = 10
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
    }
    
    func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default library from main bundle")
        }
        
        let vertexFunc = library.makeFunction(name: "vertex_main")
        let fragmentFunc = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        
        let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not make render pipeline. \(error)")
        }
    }
    
    static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    static func buildVertexDescriptor() -> MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: MemoryLayout<Float>.size * 3,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                            format: .float2,
                                                            offset: MemoryLayout<Float>.size * 6,
                                                            bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        return vertexDescriptor
    }
    
    static func buildScene(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) -> Scene {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
     
        let scene = Scene()
     
        scene.ambientLightColor = SIMD3<Float>(0.01, 0.01, 0.01)
        let light0 = Light(worldPosition: SIMD3<Float>( 2,  2, 2), color: SIMD3<Float>(1, 0.75, 0.75))
        let light1 = Light(worldPosition: SIMD3<Float>(-2,  2, 2), color: SIMD3<Float>(1, 1, 1))
        let light2 = Light(worldPosition: SIMD3<Float>( 0, -2, 2), color: SIMD3<Float>(1, 1, 1))
        scene.lights = [ light0, light1, light2 ]
        
        let duckURL = Bundle.main.url(forResource: "bob", withExtension: "obj")!
        let duckAsset = MDLAsset(url: duckURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        /// BUILD BOB
     
        let bob = Node(name: "Bob")
        let bobMaterial = Material()
        let bobBaseColorTexture = try? textureLoader.newTexture(name: "bob_baseColor",
                                                                scaleFactor: 1.0,
                                                                bundle: nil,
                                                                options: options)
        bobMaterial.baseColorTexture = bobBaseColorTexture
        bobMaterial.specularPower = 100
        bobMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
        bob.material = bobMaterial
        bob.mesh = try! MTKMesh.newMeshes(asset: duckAsset, device: device).metalKitMeshes.first!
        scene.rootNode.children.append(bob)
        
        /// BUILD ROSE
        
        let rose = Node(name: "Rose")
        let roseMaterial = Material()
        let roseBaseColorTexture = try? textureLoader.newTexture(name: "rose_baseColor",
                                                                scaleFactor: 1.0,
                                                                bundle: nil,
                                                                options: options)
        roseMaterial.baseColorTexture = roseBaseColorTexture
        roseMaterial.specularPower = 100
        roseMaterial.specularColor = SIMD3<Float>(0.8, 0.8, 0.8)
        rose.material = roseMaterial
        rose.mesh = try! MTKMesh.newMeshes(asset: duckAsset, device: device).metalKitMeshes.first!
        scene.rootNode.children.append(rose)
        
        /// BUILD BLUB
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
        
        let fishCount = 10
        
        let stillBlub = Node(name: "Still")
        stillBlub.material = blubMaterial
        stillBlub.material.specularPower = 1000
        stillBlub.mesh = blubMesh
        scene.rootNode.children.append(stillBlub)
         
        for i in 1...fishCount {
            let blub = Node(name: "Blub \(i)")
            blub.material = blubMaterial
            blub.mesh = blubMesh
            
            if (i % 2 == 0) {
                bob.children.append(blub)
            } else {
                rose.children.append(blub)
            }
        }
     
        return scene
    }

    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        update(view)
        
       let commandBuffer = commandQueue.makeCommandBuffer()!
       if let renderPassDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
           let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
           commandEncoder.setFrontFacing(.counterClockwise)
           commandEncoder.setCullMode(.back)
           commandEncoder.setDepthStencilState(depthStencilState)
           commandEncoder.setRenderPipelineState(renderPipeline)
           commandEncoder.setFragmentSamplerState(samplerState, index: 0)
           drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
           commandEncoder.endEncoding()
           commandBuffer.present(drawable)
           commandBuffer.commit()
       }
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
     
        if let mesh = node.mesh, let baseColorTexture = node.material.baseColorTexture {
            let viewProjectionMatrix = projectionMatrix * viewMatrix
            var vertexUniforms = VertexUniforms(viewProjectionMatrix: viewProjectionMatrix,
                                                modelMatrix: modelMatrix,
                                                normalMatrix: modelMatrix.normalMatrix)
            commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.size, index: 1)
     
            var fragmentUniforms = FragmentUniforms(cameraWorldPosition: cameraWorldPosition,
                                                    ambientLightColor: scene.ambientLightColor,
                                                    specularColor: node.material.specularColor,
                                                    specularPower: node.material.specularPower,
                                                    light0: scene.lights[0],
                                                    light1: scene.lights[1],
                                                    light2: scene.lights[2])
            commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.size, index: 0)
     
            commandEncoder.setFragmentTexture(baseColorTexture, index: 0)
     
            let vertexBuffer = mesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
     
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
     
        for child in node.children {
            drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
        }
    }
}
