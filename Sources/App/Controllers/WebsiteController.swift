import Vapor
import Leaf
import Fluent

struct WebsiteController: RouteCollection {
  func boot(router: Router) throws {
    
    router.get(use: indexHandler)
    router.get("comments", UserComment.parameter, use: userCommentHandler)
    router.get("users", User.parameter, use: userHandler)
    router.get("users", use: allUsersHandler)
    router.get("categories", use: allCategoriesHandler)
    router.get("categories", Category.parameter, use: categoriesHandler)
    router.get("comments", "create", use: createUserCommentHandler)
    router.post(CreateUserCommentData.self, at: "comments", "create", use: createUserCommentPostHandler)
    router.get("comments", UserComment.parameter, "edit", use: editUserCommentHandler)
    router.post("comments", UserComment.parameter, "edit", use: editUserCommentPostHandler)
    router.post("comments", UserComment.parameter, "delete", use: deleteUserCommentHandler)
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
            //            let context = UserCommentContext(title: userComment.comment, userComment: userComment, user: user)
            let categories = try userComment.categories.query(on: req).all()
            let context = UserCommentContext(title: userComment.comment, userComment: userComment, user: user, categories: categories)
            return try req.view().render("comments", context)
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
  
  // Leaf can handle Futures, AllCategoryContext takes Future<[Category]>, no need to unwrap here
  func allCategoriesHandler(_ req: Request) throws -> Future<View> {
    let categories = Category.query(on: req).all()
    let context = AllCategoriesContext(categories: categories)
    return try req.view().render("allCategories", context)
  }
  
  func categoriesHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(Category.self)
      .flatMap(to: View.self) { category in
        let userComments = try category.userComments.query(on: req).all()
        let context = CategoryContext(title: category.name, category: category, userComments: userComments)
        return try req.view().render("category", context)
    }
  }
  
  
  // Next 2 handlers take care of creating a new handler page and functionality
  // GET handler for the page to get all the users
  func createUserCommentHandler(_ req: Request) throws -> Future<View> {
    let context = CreateUserCommentContext(users: User.query(on: req).all())
    return try req.view().render("createComment", context)
  }
  // POST handler to process the form data
  //  func createUserCommentPostHandler(_ req: Request, userComment: UserComment) throws -> Future<Response> {
  //    return userComment.save(on: req)
  //      .map(to: Response.self) { userComment in
  //        guard let id = userComment.id else { throw Abort(.internalServerError) }
  //        return req.redirect(to: "/comments/\(id)")
  //    }
  //  }
  func createUserCommentPostHandler(_ req: Request, data: CreateUserCommentData) throws -> Future<Response> {
    let userComment = UserComment(timestamp: data.timestamp, userComment: data.comment, userID: data.userID)
    return userComment.save(on: req)
      .flatMap(to: Response.self) { userComment in
        guard let id = userComment.id else { throw Abort(.internalServerError) }
        
        var categorySaves: [Future<Void>] = []
        for category in data.categories ?? [] {
          try categorySaves.append(Category.addCategory(category, to: userComment, on: req))
        }
        
        let redirect = req.redirect(to: "/comments/\(id)")
        return categorySaves.flatten(on: req).transform(to: redirect)
    }
  }
  
  
  // GET request for editing a comment. Re-uses the createAcronym Leaf template
  func editUserCommentHandler(_ req: Request) throws -> Future<View> {
    return try req.parameters.next(UserComment.self)
      .flatMap(to: View.self) { userComment in
        //        let context = EditUserCommentContext(userComment: userComment, users: User.query(on: req).all())
        let categories = try userComment.categories.query(on: req).all()
        let context = EditUserCommentContext(userComment: userComment, users: User.query(on: req).all(), categories: categories)
        return try req.view().render("createComment", context)
    }
  }
  // POST request for editing a comment => Processing the form data from the page
  func editUserCommentPostHandler(_ req: Request) throws -> Future<Response> {
    return try flatMap(to: Response.self,
                       req.parameters.next(UserComment.self),
                       req.content.decode(CreateUserCommentData.self)) { userComment, data in
                        userComment.comment = data.comment
                        userComment.timestamp = data.timestamp
                        userComment.userID = data.userID
                        
                        return userComment.save(on: req).flatMap(to: Response.self) { savedUserComment in
                          guard let id = savedUserComment.id else { throw Abort(.internalServerError) }
                          
                          return try userComment.categories.query(on: req).all()
                            .flatMap(to: Response.self) { existingCategories in
                              let existingStringArray = existingCategories.map { $0.name }
                              let existingSet = Set<String>(existingStringArray)
                              let newSet = Set<String>(data.categories ?? [])
                              let categoriesToAdd = newSet.subtracting(existingSet)
                              let categoriesToRemove = existingSet.subtracting(newSet)
                              
                              var categoryResults: [Future<Void>] = []
                              for newCategory in categoriesToAdd {
                                categoryResults.append(try Category.addCategory(newCategory, to: userComment, on: req))
                              }
                              for categoryNameToRemove in categoriesToRemove {
                                let categoryToRemove = existingCategories.first { $0.name == categoryNameToRemove }
                                if let category = categoryToRemove {
                                  categoryResults.append(userComment.categories.detach(category, on: req))
                                }
                              }
                              
                              return categoryResults.flatten(on: req)
                                .transform(to: req.redirect(to: "/comments/\(id)"))
                          }
                        }
    }
  }
  
  // Use POST request to delete a comment (You could send DELETE request with JavaScript instead of
  // doing this work around
  func deleteUserCommentHandler(_ req: Request) throws -> Future<Response> {
    return try req.parameters.next(UserComment.self).delete(on: req)
      .transform(to: req.redirect(to: "/"))
  }
  
}

// Data for index view.
struct IndexContent: Encodable {
  let title: String
  let userComments: [UserComment]?
}

// Data for UserComment context to show a detailed view
struct UserCommentContext: Encodable {
  //  let timestamp: String
  let title: String
  let userComment: UserComment
  let user: User
  let categories: Future<[Category]>
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

// Data for all categories view
struct AllCategoriesContext: Encodable {
  let title = "All Categories"
  let categories: Future<[Category]> // No need to access resolved Future in handler if we make
  // Leaf to handle Futures
}

// Data for the new category page, where user creates categories
struct CategoryContext: Encodable {
  let title: String
  let category: Category
  let userComments: Future<[UserComment]>
}

struct CreateUserCommentContext: Encodable {
  let title = "Create Comment"
  let users: Future<[User]>
}

struct EditUserCommentContext: Encodable {
  let title = "Edit Comment"
  let userComment: UserComment
  let users: Future<[User]>
  let editing = true // Flag to tell the template that the page is for editing
  let categories: Future<[Category]>
}

// For creating or attaching category to a comment in web app
struct CreateUserCommentData: Content {
  let userID: User.ID
  let comment: String
  let timestamp: String
  let categories: [String]?
}
