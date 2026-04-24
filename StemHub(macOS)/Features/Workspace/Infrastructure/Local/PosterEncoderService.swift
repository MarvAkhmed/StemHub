//
//  PosterEncoderService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 16.04.2026.
//

import AppKit


protocol PosterEncoding {
    func encodeBase64JPEG(from image: NSImage, compression: CGFloat) throws -> String
}

final class PosterEncoderService: PosterEncoding {
    func encodeBase64JPEG(from image: NSImage, compression: CGFloat = 0.7) throws -> String {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: compression])
        else {
            throw PosterEncodingError.invalidImage
        }

        return jpegData.base64EncodedString()
    }
}

