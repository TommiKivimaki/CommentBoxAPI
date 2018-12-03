@testable import App
import FluentPostgreSQL
import Crypto

extension User {
//  static func create(name: String = "Luke", username: String = "lukes", on connection: PostgreSQLConnection) throws -> User {
//
//    let user = User(name: name, username: username)
//    return try user.save(on: connection).wait()
//  }
//}

  static func create(name: String = "Luke", username: String? = nil, on connection: PostgreSQLConnection) throws -> User {
    var createUsername: String
    
    if let suppliedUsername = username {
      createUsername = suppliedUsername
    } else {
      createUsername = UUID().uuidString
    }
    
    let password = try BCrypt.hash("password")
    let user = User(name: name, username: createUsername, password: password)
    
    return try user.save(on: connection).wait()
  }
}

extension UserComment {
  static func create(timestamp: String = "No time", comment: String = "test comment", user: User? = nil, on connection: PostgreSQLConnection ) throws -> UserComment {
    
    var userCommentsUser = user
    if userCommentsUser == nil {
      userCommentsUser = try User.create(on: connection)
    }
    
    let userComment = UserComment(timestamp: timestamp, userComment: comment, userID: userCommentsUser!.id!)
    
    return try userComment.save(on: connection).wait()
  }
}

// Simplify creating categories to database
extension App.Category {
  static func create(name: String = "Random", on connection: PostgreSQLConnection) throws -> App.Category {
    
    let category = Category(name: name)
    return try category.save(on: connection).wait()
  }
}
