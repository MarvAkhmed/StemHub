//
//  FirebaseGoogleAuthProvider.swift
//  StemHub(macOS)
//
//  Created by Marwa Awad on 07.04.2026.
//


import Foundation
import FirebaseAuth
import GoogleSignIn

final class FirebaseGoogleAuth: GoogleAuth {
    private let runtimeValidator: GoogleSignInRuntimeValidating
    
    init(runtimeValidator: GoogleSignInRuntimeValidating) {
        self.runtimeValidator = runtimeValidator
    }
    
    func signInWithGoogle() async throws -> User {
        try runtimeValidator.validate(in: .main)
        
        let authResult = try await signIn()
        return User(firebaseUser: authResult.user)
    }
    
    func signIn() async throws -> AuthDataResult {
        #if os(macOS)
        let googleUser = try await signInGoogleUserOnMacOS()
        #elseif os(iOS)
        let googleUser = try await signInGoogleUserOniOS()
        #endif
        return try await authenticateWithFirebase(using: googleUser)
    }
    
    func signOut() throws{
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }
}

#if os(iOS)
private extension FirebaseGoogleAuth {
    func signInGoogleUserOniOS() async throws -> GIDGoogleUser {
        return try await withCheckedThrowingContinuation { continuation in
            guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
                    ?? UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap(\.windows)
                .first?.rootViewController else {
                continuation.resume(throwing: AuthError.noRootViewController)
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                self.resolveGoogleSignIn(result: result, error: error, continuation: continuation)
            }
        }
    }
}
#endif

#if os(macOS)
private extension FirebaseGoogleAuth {
    func signInGoogleUserOnMacOS() async throws -> GIDGoogleUser {
        return try await withCheckedThrowingContinuation { continuation in
            let window = NSApplication.shared.keyWindow
            ?? NSApplication.shared.mainWindow
            ?? NSApplication.shared.windows.first
            
            guard let window else {
                continuation.resume(throwing: AuthError.noWindow)
                return
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: window) { result, error in
                self.resolveGoogleSignIn(result: result, error: error, continuation: continuation)
            }
        }
    }
}
#endif

private extension FirebaseGoogleAuth {
    func authenticateWithFirebase(using googleUser: GIDGoogleUser) async throws -> AuthDataResult {
        let credential = try makeFirebaseCredential(from: googleUser)
        
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let authResult {
                    continuation.resume(returning: authResult)
                } else {
                    continuation.resume(throwing: AuthError.unknown)
                }
            }
        }
    }
    
    func makeFirebaseCredential(from googleUser: GIDGoogleUser) throws -> AuthCredential {
        guard let idToken = googleUser.idToken?.tokenString else {
            throw AuthError.missingGoogleTokens
        }
        
        let accessToken = googleUser.accessToken.tokenString
        return FirebaseAuth.GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
    }
    
    func resolveGoogleSignIn(result: GIDSignInResult?, error: Error?,
                             continuation: CheckedContinuation<GIDGoogleUser, Error>) {
        if let error {
            continuation.resume(throwing: mapGoogleSignInError(error))
            return
        }
        
        guard let googleUser = result?.user else {
            continuation.resume(throwing: AuthError.missingGoogleTokens)
            return
        }
        
        continuation.resume(returning: googleUser)
    }
    
    func mapGoogleSignInError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == kGIDSignInErrorDomain else {
            return error
        }
        
        switch nsError.code {
        case GIDSignInError.canceled.rawValue:
            return AuthError.googleSignInCancelled
            
        case GIDSignInError.keychain.rawValue, GIDSignInError.hasNoAuthInKeychain.rawValue:
            return AuthError.googleSignInKeychainFailure
            
        default:
            return error
        }
    }
}
