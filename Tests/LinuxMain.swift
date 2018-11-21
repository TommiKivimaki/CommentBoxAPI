import XCTest
@testable import AppTests

XCTMain([
  testCase(UserCommentTests.allTests),
  testCase(CategoryTests.allTests),
  testCase(UserTests.allTests)
  ])
