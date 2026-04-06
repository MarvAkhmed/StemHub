//
//  FilePickerService.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 05.04.2026.
//

import Foundation
import SwiftUI

protocol FilePickerService {
    func selectFolder() async -> URL?
    func selectImage() async -> NSImage?
}
