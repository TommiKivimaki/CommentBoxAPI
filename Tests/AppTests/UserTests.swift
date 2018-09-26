@testable import App
import Vapor
import XCTest
//import FluentPostgreSQL

final class UserTests: XCTestCase {
  
  func testHelloEndpoint() throws {
    let excpectedHello = "Hello! I'm running the API for the Comment Box"
    
    var config = Config.default()
    var services = Services.default()
    var env = Environment.testing
    
    try App.configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try App.boot(app)
    
    let responder = try app.make(Responder.self) // 5
    
    let request = HTTPRequest(method: .GET, url: URL(string: "hello")!)
    let wrappedRequest = Request(http: request, using: app)
    
    let response = try responder.respond(to: wrappedRequest).wait() // 7
    
    let data = response.http.body.data!
    let responseString = String(decoding: data, as: UTF8.self)
    print(responseString)
    
    XCTAssertEqual(responseString, excpectedHello)
    
  }
  
  func testAddingComment() throws {
    
    let currentDate = Date().description
    let comment = UserComment(timestamp: currentDate, user: "Tommi")
    
    var config = Config.default()
    var services = Services.default()
    var env = Environment.testing
    
    try App.configure(&config, &env, &services)
    let app = try Application(config: config, environment: env, services: services)
    try App.boot(app)
    
    let responder = try app.make(Responder.self)
    
    var request = HTTPRequest(method: .POST, url: URL(string: "/api/comments")!)
    request.headers.add(name: "Content-Type", value: "application/json")
    request.headers.add(name: "Accept", value: "application/json")
    let encodedComment = try JSONEncoder().encode(comment)
    request.body = HTTPBody(data: encodedComment)
    let wrappedRequest = Request(http: request, using: app)
    
    let response = try responder.respond(to: wrappedRequest).wait()
    
    let data = response.http.body.data!
    let returnedComment = try JSONDecoder().decode(UserComment.self, from: data)
    
    XCTAssertEqual(comment, returnedComment)
    
    print(String(decoding: data, as: UTF8.self))
  }
  
  
  
}
