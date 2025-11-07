import Foundation

public struct MTLRenderPipelineEncoder {
    public struct Parameter {
        public enum Kind { case buffer, texture, sampler }
        public var name: String
        public var swiftTypeName: String
        public var kind: Kind
        public var stage: ASTShader.Kind
        public var index: Int
        public var isOptional: Bool
    }

    public var shaderNameVertex: String
    public var shaderNameFragment: String?
    public var swiftName: String
    public var accessLevel: AccessLevel
    public var parameters: [Parameter]
    public var vertexConstants: [ASTFunctionConstant]
    public var fragmentConstants: [ASTFunctionConstant]

    public var shaderString: String {
        let builder = SourceStringBuilder()
        builder.begin()
        builder.add(line: "\(accessLevel.rawValue) final class \(swiftName) {")
        builder.blankLine()
        builder.pushLevel()
        builder.add(line: "\(accessLevel.rawValue) let pipelineState: MTLRenderPipelineState")
        builder.blankLine()
        builder.add(line: "\(accessLevel.rawValue) init(library: MTLLibrary, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {")
        builder.pushLevel()
        builder.add(line: "let descriptor = MTLRenderPipelineDescriptor()")
        emitFunctionAssignment(builder: builder, stage: "vertex", name: shaderNameVertex, constants: vertexConstants)
        if let fragmentName = shaderNameFragment {
            emitFunctionAssignment(builder: builder, stage: "fragment", name: fragmentName, constants: fragmentConstants)
        }
        builder.add(line: "descriptor.colorAttachments[0].pixelFormat = pixelFormat")
        builder.add(line: "self.pipelineState = try library.device.makeRenderPipelineState(descriptor: descriptor)")
        builder.popLevel()
        builder.add(line: "}")
        builder.blankLine()
        let signature = parameterSignatureAndInvocation()
        builder.add(line: "\(accessLevel.rawValue) func callAsFunction(\(signature.signature)) {")
        builder.pushLevel()
        builder.add(line: "self.encode(\(signature.call))")
        builder.popLevel()
        builder.add(line: "}")
        builder.blankLine()
        builder.add(line: "\(accessLevel.rawValue) func encode(\(signature.signature)) {")
        builder.pushLevel()
        builder.add(line: "encoder.setRenderPipelineState(self.pipelineState)")
        emitParameterBindings(builder: builder)
        builder.popLevel()
        builder.add(line: "}")
        builder.popLevel()
        builder.add(line: "}")
        return builder.result
    }

    private func emitFunctionAssignment(builder: SourceStringBuilder, stage: String, name: String, constants: [ASTFunctionConstant]) {
        if constants.isEmpty {
            builder.add(line: "descriptor.\(stage)Function = library.makeFunction(name: \"\(name)\")")
        } else {
            builder.add(line: "do {")
            builder.pushLevel()
            builder.add(line: "let constantValues = MTLFunctionConstantValues()")
            for constant in constants {
                switch constant.type {
                case .ushort2:
                    builder.add(line: "constantValues.set(\(constant.name), type: .ushort2, at: \(constant.index))")
                default:
                    builder.add(line: "constantValues.set(\(constant.name), at: \(constant.index))")
                }
            }
            builder.add(line: "descriptor.\(stage)Function = try library.makeFunction(name: \"\(name)\", constantValues: constantValues)")
            builder.popLevel()
            builder.add(line: "} catch { throw error }")
        }
    }

    private func parameterSignatureAndInvocation() -> (signature: String, call: String) {
        var signatureItems: [String] = ["encoder: MTLRenderCommandEncoder"]
        var callItems: [String] = ["encoder: encoder"]
        for parameter in parameters {
            let name = parameter.name
            switch parameter.kind {
            case .buffer:
                signatureItems.append("\(name): \(parameter.swiftTypeName)")
                signatureItems.append("\(name)Offset: Int = 0")
                callItems.append("\(name): \(name)")
                callItems.append("\(name)Offset: \(name)Offset")
            case .texture, .sampler:
                signatureItems.append("\(name): \(parameter.swiftTypeName)")
                callItems.append("\(name): \(name)")
            }
        }
        return (signatureItems.joined(separator: ", "), callItems.joined(separator: ", "))
    }

    private func emitParameterBindings(builder: SourceStringBuilder) {
        for parameter in parameters {
            let name = parameter.name
            switch parameter.kind {
            case .buffer:
                let call = parameter.stage == .vertex ? "setVertexBuffer" : "setFragmentBuffer"
                if parameter.isOptional {
                    builder.add(line: "if let buffer = \(name) { encoder.\(call)(buffer, offset: \(name)Offset, index: \(parameter.index)) }")
                } else {
                    builder.add(line: "encoder.\(call)(\(name), offset: \(name)Offset, index: \(parameter.index))")
                }
            case .texture:
                let call = parameter.stage == .vertex ? "setVertexTexture" : "setFragmentTexture"
                if parameter.isOptional {
                    builder.add(line: "if let texture = \(name) { encoder.\(call)(texture, index: \(parameter.index)) }")
                } else {
                    builder.add(line: "encoder.\(call)(\(name), index: \(parameter.index))")
                }
            case .sampler:
                let call = parameter.stage == .vertex ? "setVertexSamplerState" : "setFragmentSamplerState"
                if parameter.isOptional {
                    builder.add(line: "if let sampler = \(name) { encoder.\(call)(sampler, index: \(parameter.index)) }")
                } else {
                    builder.add(line: "encoder.\(call)(\(name), index: \(parameter.index))")
                }
            }
        }
    }
}
