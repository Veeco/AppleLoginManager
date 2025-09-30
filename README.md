# AppleLoginManager

一个简单易用的 Apple 登录管理器，支持 Swift Package Manager。

## 功能特性

- 简化 Apple 登录流程
- 支持获取用户身份信息
- 错误处理和状态管理
- 支持 iOS 13+ 和 macOS 10.15+

## 安装

### Swift Package Manager

在 Xcode 中：
1. 选择 `File` > `Add Package Dependencies...`
2. 输入仓库 URL：`https://github.com/veeco/AppleLoginManager.git`
3. 选择版本并添加到项目

或者在 `Package.swift` 中添加依赖：

```swift
dependencies: [
    .package(url: "https://github.com/veeco/AppleLoginManager.git", from: "1.0.0")
]
```

## 使用方法

### 基本用法

```swift
import AppleLoginManager

// 调用 Apple 登录
AppleLoginManager.signInWithApple { result in
    switch result {
    case .success(let loginResult):
        print("登录成功")
        print("用户ID: \(loginResult.userIdentifier)")
        print("邮箱: \(loginResult.email ?? "未提供")")
        print("姓名: \(loginResult.fullName?.formatted() ?? "未提供")")
        
    case .failure(let error):
        print("登录失败: \(error.localizedDescription)")
    }
}
```

### AppleLoginResult 结构

```swift
struct AppleLoginResult {
    let userIdentifier: String      // 用户唯一标识符
    let email: String?              // 用户邮箱（可选）
    let fullName: PersonNameComponents? // 用户姓名（可选）
    let identityToken: String?      // 身份令牌（可选）
    let authorizationCode: String?  // 授权码（可选）
    let state: String?              // 状态信息（可选）
}
```

### 错误处理

```swift
enum AppleLoginError: Error {
    case invalidCredential          // 无效的登录凭证
    case noIdentityToken           // 无法获取身份令牌
    case tokenSerializationFailed  // 令牌序列化失败
    case requestInProgress         // 登录请求正在进行中
}
```

## 要求

- iOS 13.0+ / macOS 10.15+
- Xcode 12.0+
- Swift 5.7+

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！