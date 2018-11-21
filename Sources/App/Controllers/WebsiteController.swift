import Vapor
import Leaf

struct WebsiteController: RouteCollection {
  func boot(router: Router) throws {
    
    router.get(use: indexHandler)
    router.get("comments", UserComment.parameter, use: userCommentHandler)
  }
  
  func indexHandler(_ req: Request) throws -> Future<View> {
    return UserComment.query(on: req)
      .all()
      .flatMap(to: View.self) { userComments in
        let userCommentsData = userComments.isEmpty ? nil : userComments
        let context = IndexContent(title: "User Comments", userComments: userCommentsData)
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
