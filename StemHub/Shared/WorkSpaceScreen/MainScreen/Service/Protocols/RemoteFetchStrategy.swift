//
//  RemoteFetchStrategy.swift
//  StemHub
//
//  Created by Marwa Awad on 02.04.2026.
//

import Foundation

protocol RemoteFetchStrategy {
    func fetchRemoteSnapshot(versionID: String) async throws -> [RemoteFileSnapshot]
    func fetchProjectVersion(versionID: String) async throws -> ProjectVersion?
}
