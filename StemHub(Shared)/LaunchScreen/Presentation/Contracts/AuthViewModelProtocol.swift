//
//  AuthViewModelProtocol.swift
//  StemHub
//
//  Created by Marwa Awad on 06.04.2026.
//

import Foundation

protocol AuthViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var alertItem: AlertItem? { get set }
    var isAuthenticated: Bool { get }
    var currentUser: User? { get }
    var isLoadingMessage: String { get }

    func signUp(email: String, password: String, confirmPassword: String) async
    func signIn(email: String, password: String) async
    func signInWithGoogle() async
    func resetPassword(email: String) async
    func logout()
}
