// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "CommentBoxAPI",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/vapor/fluent-postgresql.git", from: "1.0.0"),
        
        // Adding Leaf
      .package(url: "https://github.com/vapor/leaf.git", from: "3.0.2"),
        // HTTP Authentication support
      .package(url: "https://github.com/vapor/auth.git", from: "2.0.1")
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostgreSQL", "Vapor", "Leaf", "Authentication"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

