import Vapor
import App
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
                      body: T? = nil) throws -> Response where T: Content {
    
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
                      headers: HTTPHeaders = .init()) throws -> Response {
    
    // Create emptyContent to satisfy compiler for a body parameter
    let emptyContent: EmptyContent? = nil
    return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
  }
  
  /// Convenience method to send a request with generic Content type and when we don't care about the response.
  func sendRequest<T>(to path: String,
                      method: HTTPMethod,
                      headers: HTTPHeaders = .init(),
                      data: T) throws where T: Content {
    
    _ = try self.sendRequest(to: path, method: method, headers: headers, body: data)
  }
  
  /// Generic method to get a response to a request
  func getResponse<C, T>(to path: String,
                         method: HTTPMethod = .GET,
                         headers: HTTPHeaders = .init(),
                         data: C? = nil,
                         decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
    
    // Send the request
    let response = try self.sendRequest(to: path, method: method, headers: headers, body: data)
    // Decode the response body to a generic type and return the result
    return try response.content.decode(type).wait()
  }
  
  /// Convenience method to get a response without providing a body
  func getResponse<T>(to path: String,
                      method: HTTPMethod = .GET,
                      headers: HTTPHeaders = .init(),
                      decodeTo type: T.Type) throws -> T where T: Decodable {

    // Create empty content to satisfy compiler
    let emptyContent: EmptyContent? = nil
    // Use previous method to get a response
    return try self.getResponse(to: path, method: method, headers: headers, data: emptyContent, decodeTo: type)
  }
  
}


// Defines empty content type to use when there's no body to send in request
// Since you cannot define nil for a generic type
struct EmptyContent: Content {}
