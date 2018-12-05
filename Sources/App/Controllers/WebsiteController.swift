import Vapor
import Leaf
import Fluent
import Authentication

struct WebsiteController: RouteCollection {
  func boot(router: Router) throws {
    
    let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
    authSessionRoutes.get(use: indexHandler)
    authSessionRoutes.get("comments", UserComment.parameter, use: userCommentHandler)
    authSessionRoutes.get("users", User.parameter, use: userHandler)
    authSessionRoutes.get("users", use: allUsersHandler)
    authSessionRoutes.get("categories", use: allCategoriesHandler)
    authSessionRoutes.get("categories", Category.parameter, use: categoriesHandler)
    authSessionRoutes.get("login", use: loginHandler)
    authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
    authSessionRoutes.post("logout", use: logoutHandler)
    authSessionRoutes.get("register", use: registerHandler)
    authSessionRoutes.post(RegisterData.self, at: "register", use: registerPostHandler)
    
    let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
    protectedRoutes.get("comments", "create", use: createUserCommentHandler)
    protectedRoutes.post(CreateUserCommentData.self, at: "comments", "create", use: createUserCommentPostHandler)
    protectedRoutes.get("comments", UserComment.parameter, "edit", use: editUserCommentHandler)
    protectedRoutes.post("comments", UserComment.parameter, "edit", use: editUserCommentPostHandler)
    protectedRoutes.post("comments", UserComment.parameter, "delete", use: deleteUserCommentHandler)
    
    //    router.get(use: indexHandler)
    //    router.get("comments", UserComment.parameter, use: userCommentHandler)
    //    router.get("users", User.parameter, use: userHandler)
    //    router.get("users", use: allUsersHandler)
    //    router.get("categories", use: allCategoriesHandler)
    //    router.get("categories", Category.parameter, use: categoriesHandler)
    //    router.get("comments", "create", use: createUserCommentHandler)
    //    router.post(CreateUserCommentData.self, at: "comments", "create", use: createUserCommentPostHandler)
    //    router.get("comments", UserComment.parameter, "edit", use: editUserCommentHandler)
    //    router.post("comments", UserComment.parameter, "edit", use: editUserCommentPostHandler)
    //    router.post("comments", UserComment.parameter, "delete", use: deleteUserCommentHandler)
    //    router.get("login", use: loginHandler)
    //    router.post(LoginPostData.self, at: "login", use: loginPostHandler)
  }
  
  func indexHandler(_ req: Request) throws -> Future<View> {
    // Check if request contains authenticated user
    let userLoggedIn = try req.isAuthenticated(User.self)
    return UserComment.query(on: req)
      .all()
      .flatMap(to: View.self) { userComments in
        let userCommentsData = userComments.isEmpty ? nil : userComments
        // Check if cookies-accepted exists
        let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
        let context = IndexContext(title: "Comment Box", userLoggedIn: userLoggedIn, userComments: userCommentsData, showCookieMessage: showCookieMessage)
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
    // Creates CSRF token
    let token = try CryptoRandom().generateData(count: 16).base64EncodedString()
    let context = CreateUserCommentContext(csrfToken: token)
    try req.session()["CSRF_TOKEN"] = token // Save the token into the session under CSRF_TOKEN key
    
    return try req.view().render("createComment", context)
  }
  
  // POST handler to process the form data
  func createUserCommentPostHandler(_ req: Request, data: CreateUserCommentData) throws -> Future<Response> {
    // Check the CSRF_TOKEN
    let expectedToken = try req.session()["CSRF_TOKEN"]
    try req.session()["CSRF_TOKEN"] = nil
    guard expectedToken == data.csrfToken else { throw Abort(.badRequest) }
    
    // Get the user from the req. We know there is a user since this path requires authentication
    let user = try req.requireAuthenticated(User.self)
    let userComment = UserComment(timestamp: data.timestamp, userComment: data.comment, userID: try user.requireID())
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
        let categories = try userComment.categories.query(on: req).all()
        let context = EditUserCommentContext(userComment: userComment, categories: categories)
        return try req.view().render("createComment", context)
    }
  }
  // POST request for editing a comment => Processing the form data from the page
  func editUserCommentPostHandler(_ req: Request) throws -> Future<Response> {
    // Get the user from the req. We know there is a user since this path requires authentication
    let user = try req.requireAuthenticated(User.self)
    return try flatMap(to: Response.self,
                       req.parameters.next(UserComment.self),
                       req.content.decode(CreateUserCommentData.self)) { userComment, data in
                        userComment.comment = data.comment
                        userComment.timestamp = data.timestamp
                        userComment.userID = try user.requireID()
                        
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
  
  
  // Handles the login web page
  func loginHandler(_ req: Request) throws -> Future<View> {
    let context: LoginContext
    
    // If request contains error parameter, create a context with loginError set to true
    if req.query[Bool.self, at: "error"] != nil {
      context = LoginContext(loginError: true)
    } else {
      context = LoginContext()
    }
    
    return try req.view().render("login", context)
  }
  
  // Decodes the POST data sent from login page
  func loginPostHandler(_ req: Request, userData: LoginPostData ) throws -> Future<Response> {
    // Check the user against database and verify the BCrypt hash. Returns nil if it fails
    return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(), on: req).map(to: Response.self) { user in
      // Check if authentication fails.
      guard let user = user else { return req.redirect(to: "/login?error") }
      try req.authenticateSession(user)
      return req.redirect(to: "/")
    }
  }
  
  
  // Handles the log out. There's no async work on this handler, so there no need to return a Future<Response>
  func logoutHandler(_ req: Request) throws -> Response {
    try req.unauthenticateSession(User.self)
    return req.redirect(to: "/")
  }
  
  // For the Register page
  func registerHandler(_ req: Request) throws -> Future<View> {
    let context: RegisterContext
    // If query includes a message `/register?message=some-string` include the message into the context to show in page
    if let message = req.query[String.self, at: "message"] {
      context = RegisterContext(message: message)
    } else {
      context = RegisterContext()
    }
    return try req.view().render("register", context)
  }
  
  // POST handler for the Register page
  // FIXME: This does not handle the error case of unique key constraint violation! Proper error message should be displayed. Now
  // the unique key value violation just send error text to web page. Should first check if user exists then either show an eror message or save user.
  func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
   // Validate the post data first
    do {
      try data.validate()
    } catch (let error) {
      let redirect: String
      if let error = error as? ValidationError,
        let message = error.reason.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        redirect = "/register?message=\(message)"
      } else {
        redirect = "/register?message=Unknown+Error"
      }
      
      return req.future(req.redirect(to: redirect))
    }
    
    // Hash the password and store it
    let password = try BCrypt.hash(data.password)
    let user = User(name: data.name, username: data.username, password: password)
    return user.save(on: req).map(to: Response.self) { user in
      try req.authenticateSession(user)
      return req.redirect(to: "/")
    }
  }
  
}

// Data for index view.
struct IndexContext: Encodable {
  let title: String
  let userLoggedIn: Bool
  let userComments: [UserComment]?
  let showCookieMessage: Bool
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
  let csrfToken: String
}

struct EditUserCommentContext: Encodable {
  let title = "Edit Comment"
  let userComment: UserComment
  let editing = true // Flag to tell the template that the page is for editing
  let categories: Future<[Category]>
}

// For creating or attaching category to a comment in web app
struct CreateUserCommentData: Content {
  let comment: String
  let timestamp: String
  let categories: [String]?
  let csrfToken: String? // Optional so that decoding succeeds even if token is missing. `Guard let` check can then respond
                         // with .badRequest from createUserCommentPostHandler
}



//
// For Login page
//

struct LoginContext: Encodable {
  let title = "Log in"
  let loginError: Bool
  
  init(loginError: Bool = false) {
    self.loginError = loginError
  }
}

struct LoginPostData: Content {
  let username: String
  let password: String
}

// Context for Register page
struct RegisterContext: Encodable {
  let title = "Register"
  let message: String?
  
  init(message: String? = nil) {
    self.message = message
  }
}
// Data received from the form in Register page
struct RegisterData: Content {
  let name: String
  let username: String
  let password: String
  let confirmPassword: String
}
// Validate the data send from the Register page form
extension RegisterData: Validatable, Reflectable {
  static func validations() throws -> Validations<RegisterData> {
    var validations = Validations(RegisterData.self)
    try validations.add(\.name, .ascii)
    try validations.add(\.username, .alphanumeric && .count(3...))
    try validations.add(\.password, .count(8...))
    
    // custom validation to check that the passwords match
    validations.add("passwords match") { model in
      guard model.password == model.confirmPassword else { throw BasicValidationError("Passwords don't match") }
    }
    
    return validations
  }
}
