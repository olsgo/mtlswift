import Foundation
import ArgumentParser

extension MTLSwift {

    struct Generate: ParsableCommand {

        @OptionGroup()
        var options: Options

        func validate() throws {
            if let outputPath = self.options.outputPath,
                !outputPath.contains(".swift") {
                throw ValidationError("Output file extension is not `.swift`")
            }
        }

        func run() throws {
            let shadersFilesFilteredURLs = Array(try MTLSwift
                .findShadersFiles(at: self.options.inputPaths,
                                  isRecursive: self.options.isRecursive))
            if let outputPath = self.options.outputPath {
                let outputURL = URL(fileURLWithPath: outputPath)
                shadersFilesFilteredURLs.forEach {
                    print("generating encoder for shader file on url \($0)")
                }
                try EncoderGenerator.shared.generateEncoders(for: shadersFilesFilteredURLs,
                                                             output: outputURL)
            } else {
                try shadersFilesFilteredURLs.forEach {
                    print("generating encoder for shader file on url \($0)")
                    try EncoderGenerator.shared.generateEncoders(for: [$0])
                }
            }
        }

        static let configuration = CommandConfiguration(abstract: "Generate encoders from metal sources.")
    }

}
