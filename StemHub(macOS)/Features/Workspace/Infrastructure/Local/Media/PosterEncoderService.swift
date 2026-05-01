//
//  PosterEncoderService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import AppKit

protocol PosterEncoding {
    func encodeBase64JPEG(from image: NSImage, compression: CGFloat) throws -> String
    func decodeBase64JPEG(from base64String: String) throws -> NSImage
}

final class PosterEncoderService: PosterEncoding {
    func encodeBase64JPEG(from image: NSImage, compression: CGFloat = 0.7) throws -> String {
        let jpegData = try validateCompression(from: image, compression: compression)
        return jpegData.base64EncodedString()
    }
    
    func decodeBase64JPEG(from base64String: String) throws -> NSImage {
        guard let jpegData = Data(base64Encoded: base64String) else {
            throw PosterDecodingError.invalidBase64String
        }
        guard let image = NSImage(data: jpegData) else {
            throw PosterDecodingError.failedToCreateImage
        }
        return image
    }
}

// Validator Helper
private extension PosterEncoderService {
    func validateCompression(from image: NSImage, compression: CGFloat = 0.7) throws -> Data {
        let properties: [NSBitmapImageRep.PropertyKey: CGFloat] =  [.compressionFactor: compression]
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let jpegData = bitmap.representation(using: .jpeg, properties: properties){
            return jpegData
        }
        else {
            throw PosterEncodingError.invalidImage
        }
    }
}
