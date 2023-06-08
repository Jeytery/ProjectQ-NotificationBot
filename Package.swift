// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProjectQ-NotificationBot",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
        .package(name: "TelegramBotSDK", url: "https://github.com/rapierorg/telegram-bot-swift", from: "2.1.2"),
        .package(name: "ProjectQ-Components2", url: "https://github.com/swiftonica/ProjectQ-Components2", from: "1.0.3")
    ],
    targets: [
        .executableTarget(
            name: "ProjectQ-NotificationBot",
            dependencies: ["Alamofire", "ProjectQ-Components2", "TelegramBotSDK"])
    ]
)


