import Vapor
import Leaf

struct WebsiteController: RouteCollection {
  func boot(router: Router) throws {
    
    router.get(use: indexHandler)
    router.get("comments", UserComment.parameter, use: userCommentHandler)
    router.get("users", User.parameter, use: userHandler)
    router.get("allUsers", use: allUsersHandler)
  }
  
  func indexHandler(_ req: Request) throws -> Future<View> {
    return UserComment.query(on: req)
      .all()
      .flatMap(to: View.self) { userComments in
        let userCommentsData = userComments.isEmpty ? nil : userComments
        let context = IndexContent(title: "Comment Box", userComments: userCommentsData)
        return try req.view().render("index", context)
    }
  }
  
  func userCommentHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(UserComment.self)
      .flatMap(to: View.self) { userComment in
        return userComment.user
          .get(on: req)
          .flatMap(to: View.self) { user in
            let userCommentContext = UserCommentContext(timestamp: userComment.timestamp,
                                                        userComment: userComment, user: user)
            return try req.view().render("comments", userCommentContext)
        }
    }
  }
  
  func userHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(User.self)
      .flatMap(to: View.self) { user in
        return try user.userComments
          .query(on: req)
          .all()
          .flatMap(to: View.self) { userComments in
            let userContext = UserContext(title: "User", user: user, userComments: userComments)
            return try req.view().render("users", userContext)
        }
        
    }
  }
  
  func allUsersHandler(_ req: Request) throws -> Future<View> {
    return User.query(on: req)
      .all()
      .flatMap(to: View.self) { users in
        let allUsersContext = AllUsersContext(title: "All Comment Box Users", users: users)
        return try req.view().render("allUsers", allUsersContext)
    }
  }
}

// Data for index view.
struct IndexContent: Encodable {
  let title: String
  let userComments: [UserComment]?
}

// Data for UserComment context to show a detailed view
struct UserCommentContext: Encodable {
  let timestamp: String
  let userComment: UserComment
  let user: User
}

// Data for User view
struct UserContext: Encodable {
  let title: String
  let user: User
  let userComments: [UserComment]
}

// Data for all users view
struct AllUsersContext: Encodable {
  let title: String
  let users: [User]
}
