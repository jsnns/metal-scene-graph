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
    
    let world: World

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
        self.world = World(device: device, vertexDescriptor: vertexDescriptor)
        
        super.init()
        
        buildPipeline()
    }
    
    func update(_ view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
        
        cameraWorldPosition = SIMD3<Float>(0, 1.2, 3)
        viewMatrix = float4x4(translationBy: -cameraWorldPosition) * float4x4(scaleBy: 1)
        
        // update aspect ratio to handle screen orientation changes
        let aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
        projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 10  )

        world.update(time: time)
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
           drawNodeRecursive(world.scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
           commandEncoder.endEncoding()
           commandBuffer.present(drawable)
           commandBuffer.commit()
       }
    }
    
    func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
        let modelMatrix = parentTransform * node.modelMatrix
        let scene = world.scene
     
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
    
    func keyDown(event: NSEvent) {
        self.world.keyDown(event: event)
    }
    
    func keyUp(event: NSEvent) {
        self.world.keyUp(event: event)
    }
}
