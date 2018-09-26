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
  
  
  
}
