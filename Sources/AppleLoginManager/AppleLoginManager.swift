//
//  AppleLoginManager.swift
//  AppleLoginManager
//
//  Created by Interactipie Team.
//

import Foundation
import AuthenticationServices

public struct AppleLoginResult {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String?
    let authorizationCode: String?
    let state: String?
}

public enum AppleLoginError: Error {
    case invalidCredential
    case noIdentityToken
    case tokenSerializationFailed
    case requestInProgress
    
    var localizedDescription: String {
        switch self {
        case .invalidCredential:
            return "无效的登录凭证"
        case .noIdentityToken:
            return "无法获取身份令牌"
        case .tokenSerializationFailed:
            return "令牌序列化失败"
        case .requestInProgress:
            return "Apple登录请求正在进行中"
        }
    }
}

public class AppleLoginManager: NSObject {
    
    private static let shared = AppleLoginManager()
    
    private var isRequestInProgress = false
    private var completionCallback: ((Result<AppleLoginResult, Error>) -> Void)?
    
    private override init() {
        super .init()
    }
    
    // MARK: - Public Methods
    
    public static func signInWithApple(completion: @escaping (Result<AppleLoginResult, Error>) -> Void) {
        let instance = AppleLoginManager.shared
        
        // 检查是否已有请求在进行中
        guard !instance.isRequestInProgress else {
            completion(.failure(AppleLoginError.requestInProgress))
            return
        }
        
        instance.isRequestInProgress = true
        instance.completionCallback = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = instance
        authorizationController.presentationContextProvider = instance
        authorizationController.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleLoginManager: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer {
            isRequestInProgress = false
            completionCallback = nil
        }
        
        guard let completion = completionCallback else {
            return
        }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(AppleLoginError.invalidCredential))
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            completion(.failure(AppleLoginError.noIdentityToken))
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(.failure(AppleLoginError.tokenSerializationFailed))
            return
        }
        
        let authorizationCodeString: String?
        if let authorizationCode = appleIDCredential.authorizationCode {
            authorizationCodeString = String(data: authorizationCode, encoding: .utf8)
        } else {
            authorizationCodeString = nil
        }
        
        let result = AppleLoginResult(
            userIdentifier: appleIDCredential.user,
            email: appleIDCredential.email,
            fullName: appleIDCredential.fullName,
            identityToken: idTokenString,
            authorizationCode: authorizationCodeString,
            state: appleIDCredential.state
        )
        
        // 通过回调返回结果
        completion(.success(result))
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer {
            isRequestInProgress = false
            completionCallback = nil
        }
        
        completionCallback?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleLoginManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
#if os(macOS)
        typealias Application = NSApplication
#else
        typealias Application = UIApplication
#endif
        return Application.shared.windows.first { $0.isKeyWindow } ?? Application.shared.windows.first!
    }
}
