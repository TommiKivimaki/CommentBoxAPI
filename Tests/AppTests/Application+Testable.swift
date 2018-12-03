import Vapor
@testable import App
import Authentication
import FluentPostgreSQL

extension Application {
  
  // Creates a testable app with the envArgs given
  static func testable(envArgs: [String]? = nil) throws -> Application {
    var config = Config.default()
    var services = Services.default()
    var env = Environment.testing
    
    if let environmentArgs = envArgs {
      env.arguments = environmentArgs
    }
    
    try App.configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try App.boot(app)
    return app
  }
  
  // Resets database
  static func reset() throws {
    let revertEnvironment = ["vapor", "revert", "--all", "-y"]
    try Application.testable(envArgs: revertEnvironment)
      .asyncRun()
      .wait()
    
    let migrateEnvironment = ["vapor", "migrate", "-y"]
    try Application.testable(envArgs: migrateEnvironment)
      .asyncRun()
      .wait()
  }
  
  /// Sends a request to a path and returns a Response
  func sendRequest<T>(to path: String,
                      method: HTTPMethod,
                      headers: HTTPHeaders = .init(),
                      body: T? = nil,
                      loggedInRequest: Bool = false,
                      loggedInUser: User? = nil) throws -> Response where T: Content {
    
    var headers = headers
    
    // Determine if this request requires authentication first
    if (loggedInRequest || loggedInUser != nil) {
      let username: String
      if let user = loggedInUser {
        username = user.username
      } else {
        username = "realadmin"
      }
      
      // Create credentials
      let credentials = BasicAuthorization(username: username, password: "password")
      // Create header for authentication
      var tokenHeaders = HTTPHeaders()
      tokenHeaders.basicAuthorization = credentials
      
      // Send the request to login
      let tokenResponse = try self.sendRequest(to: "api/users/login", method: .POST, headers: tokenHeaders)
      // Decode token from the response
      let token = try tokenResponse.content.syncDecode(Token.self)
      // Add the token to the authorization header we are trying to send.
      headers.add(name: .authorization, value: "Bearer \(token.token)")
    }
    
    let responder = try self.make(Responder.self)
    let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
    let wrappedRequest = Request(http: request, using: self)
    
    // If body was provided encode it into a requests content
    if let body = body {
      try wrappedRequest.content.encode(body)
    }
    
    // Send request and return a response
    return try responder.respond(to: wrappedRequest).wait()
  }
  
  
  /// Convenience method to send a request without a body
  func sendRequest(to path: String,
                   method: HTTPMethod,
                   headers: HTTPHeaders = .init(),
                   loggedInRequest: Bool = false,
                   loggedInUser: User? = nil) throws -> Response {
    
    // Create emptyContent to satisfy compiler for a body parameter
    let emptyContent: EmptyContent? = nil
    return try sendRequest(to: path, method: method, headers: headers, body: emptyContent, loggedInRequest: loggedInRequest, loggedInUser: loggedInUser)
  }
  
  
  /// Convenience method to send a request and return a response decoded to a specific type
  func getResponse<C, T>(to path: String,
                         method: HTTPMethod = .GET,
                         headers: HTTPHeaders = .init(),
                         data: C? = nil,
                         decodeTo type: T.Type,
                         loggedInRequest: Bool = false,
                         loggedInUser: User? = nil) throws -> T where C: Content, T: Decodable {
    
    let response = try self.sendRequest(to: path, method: method,
                                        headers: headers,
                                        body: data,
                                        loggedInRequest: loggedInRequest,
                                        loggedInUser: loggedInUser)
    return try response.content.decode(type).wait()
  }
  
  
  /// Convenience method: Send a request without a body and decode respose to a specific type.
  func getResponse<T>(to path: String,
                      method: HTTPMethod = .GET,
                      headers: HTTPHeaders = .init(),
                      decodeTo type: T.Type,
                      loggedInRequest: Bool = false,
                      loggedInUser: User? = nil) throws -> T where T: Content {
    
    let emptyContent: EmptyContent? = nil
    return try self.getResponse(to: path, method: method,
                                headers: headers,
                                data: emptyContent,
                                decodeTo: type,
                                loggedInRequest: loggedInRequest,
                                loggedInUser: loggedInUser)
  }
  
  
  /// Convenience method: Send a request and don't care about the response. 
  func sendRequest<T>(to path: String,
                      method: HTTPMethod,
                      headers: HTTPHeaders,
                      data: T,
                      loggedInRequest: Bool = false,
                      loggedInUser: User? = nil) throws where T: Content {
    
    _ = try self.sendRequest(to: path, method: method,
                             headers: headers,
                             body: data,
                             loggedInRequest: loggedInRequest,
                             loggedInUser: loggedInUser)
  }
  
}


// Defines empty content type to use when there's no body to send in request
// Since you cannot define nil for a generic type
struct EmptyContent: Content {}
