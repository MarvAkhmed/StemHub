//
//  AuthenticationViewModelProtocol.swift
//  StemHub
//

import Foundation
import Combine

@MainActor
final class AuthViewModel: AuthViewModelProtocol {
    
    private let authService: AuthServiceProtocol
    private let validator: AuthFormValidating
    private let errorMapper: AuthErrorMapping
    
    @Published private var activityState: AuthActivityState = .idle
    @Published var alertItem: AlertItem?
    
    var isAuthenticated: Bool { authService.isSignedIn }
    var currentUser: User? { authService.currentUser }
    
    private var cancellables = Set<AnyCancellable>()
    private var restoreSessionTask: Task<Void, Never>?
    
    var isLoading: Bool { activityState.isLoading }
    var isLoadingMessage: String { activityState.message }
    
    init(
        authService: AuthServiceProtocol,
        validator: AuthFormValidating,
        errorMapper: AuthErrorMapping
    ) {
        self.authService = authService
        self.validator = validator
        self.errorMapper = errorMapper
        
        bindWith(authService: authService)
        
        restoreSessionTask = Task {await restoreSession() }
    }
    
    convenience init(authService: AuthServiceProtocol) {
        self.init(
            authService: authService,
            validator: AuthFormValidator(),
            errorMapper: DefaultAuthErrorMapper()
        )
    }
    
    // MARK: - Public methods
    func signUp(email: String, password: String, confirmPassword: String) async {
        await performAuthOperation(message: "Creating your account...") {
            try validator.validateSignUp(email: email, password: password, confirmPassword: confirmPassword)
            _ = try await authService.signUp(email: email, password: password)
            showAlert(title: "Success", message: "Account created successfully!")
        }
    }
    
    func signIn(email: String, password: String) async {
        await performAuthOperation(message: "Signing you in...") {
            try validator.validateSignIn(email: email, password: password)
            _ = try await authService.signIn(email: email, password: password)
        }
    }
    
    func signInWithGoogle() async {
        await performAuthOperation(message: "Connecting to Google...") {
            if let user = try await authService.signInWithGoogle() {
                showAlert(title: "Success", message: "Logged in as \(user.email ?? "User")!")
            }
        }
    }
    
    func resetPassword(email: String) async {
        await performAuthOperation(message: "Sending reset email...") {
            try validator.validateResetPassword(email: email)
            try await authService.resetPassword(email: email)
            showAlert(title: "Success", message: "Password reset email sent!")
        }
    }
    
    func logout() {
        authService.logout()
    }
}

// MARK: - Private helpers
private extension AuthViewModel {
    
    func restoreSession() async {
        guard case .idle = activityState else { return }
        
        setActivity(.restoringSession)
        defer {
            restoreSessionTask = nil
            
            if case .restoringSession = activityState {
                setActivity(.idle)
            }
        }
        
        do {
            _ = try await authService.restoreSession()
        } catch is CancellationError {
            return
        } catch {
            handleError(error)
        }
    }
    
    func performAuthOperation(
        message: String,
        operation: () async throws -> Void
    ) async {
        guard !activityState.blocksUserInitiatedActions else { return }
        
        await cancelRestoreSessionIfNeeded()
        
        setActivity(.processing(message))
        defer { setActivity(.idle) }
        
        do {
            try await operation()
        } catch {
            handleError(error)
        }
    }
    
    func cancelRestoreSessionIfNeeded() async {
        restoreSessionTask?.cancel()
        _ = await restoreSessionTask?.value
        restoreSessionTask = nil
    }
    
    func setActivity(_ activityState: AuthActivityState) {
        self.activityState = activityState
    }
    
    func handleError(_ error: Error) {
        showAlert(title: "Error", message: errorMapper.message(for: error))
    }
    
    func showAlert(title: String, message: String) {
        alertItem = AlertItem(title: title, message: message)
    }
    
    func bindWith(authService: AuthServiceProtocol) {
        authService.currentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {[weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] _ in
                self?.objectWillChange.send()
            })
            .store(in: &cancellables)
        
        authService.isSignedInPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {[weak self] completion in
                if case .failure(let error) = completion {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }, receiveValue: { [weak self] _ in
                self?.objectWillChange.send()
            })
            .store(in: &cancellables)
    }
  
}
