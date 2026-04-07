//
//  FirebaseGoogleAuthProvider.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//


import Foundation
import FirebaseAuth
import GoogleSignIn

protocol GoogleSignInProvider {
    func signInWithGoogle() async throws -> AuthDataResult
}

final class FirebaseGoogleAuthProvider: GoogleSignInProvider {
    
    public init() {}
    
    func signInWithGoogle() async throws -> AuthDataResult {
        #if os(iOS)
        return try await signInOniOS()
        #elseif os(macOS)
        return try await signInOnMacOS()
        #endif
    }
    
    #if os(iOS)
    private func signInOniOS() async throws -> AuthDataResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
                continuation.resume(throwing: AuthError.noRootViewController)
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let googleUser = result?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.missingGoogleTokens)
                    return
                }
                
                let accessToken = googleUser.accessToken.tokenString
                let credential = FirebaseAuth.GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let authResult = authResult {
                        continuation.resume(returning: authResult)
                    } else {
                        continuation.resume(throwing: AuthError.unknown)
                    }
                }
            }
        }
    }
    #endif
    
    #if os(macOS)
    private func signInOnMacOS() async throws -> AuthDataResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let window = NSApplication.shared.windows.first else {
                continuation.resume(throwing: AuthError.noWindow)
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let googleUser = result?.user,
                      let idToken = googleUser.idToken?.tokenString else {
                    continuation.resume(throwing: AuthError.missingGoogleTokens)
                    return
                }
                
                let accessToken = googleUser.accessToken.tokenString
                let credential = FirebaseAuth.GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let authResult = authResult {
                        continuation.resume(returning: authResult)
                    } else {
                        continuation.resume(throwing: AuthError.unknown)
                    }
                }
            }
        }
    }
    #endif
}
