//
//  StepDefiner.swift
//  whats-new
//
//  Created by Sam Dean on 29/10/2015.
//  Copyright © 2015 net-a-porter. All rights reserved.
//

import XCTest

/**
Classes which extend this class will be queried by the system to
populate the step definitions before test runs
*/
open class StepDefiner: NSObject {
    open let test: XCTestCase
    
    required public init(test: XCTestCase) {
        self.test = test
    }
    
    /**
      Override this to create your own step definitions
     */
    open func defineSteps() -> Void { }

    /**
     Create a new step with an expression that contains no matching groups.
         
     Don't pass anything for file: or path: - these will be automagically filled out for you. Use it like this:
         
         step("Some regular expression") {
             ... some function ...
         }
     
     - parameter expression: The expression to match against
     - parameter f0: The step definition to be run
     
     */
    open func step(_ expression: String, file: String = #file, line: Int = #line, f0: @escaping ()->()) {
        self.test.addStep(expression, file: file, line: line) { (ignored: [String]) in f0() }
    }

    /**
     Create a new step with an expression that contains one or more matching groups.
     
     Don't pass anything for file: or path: - these will be automagically filled out for you. Use it like this:
     
         step("Some (regular|irregular) expression with a number ([0-9]*)") { (matches:[String]) in
             ... some function ...
         }
     
     - parameter expression: The expression to match against
     - parameter f: The step definition to be run, passing in the matches from the expression
     
     */
    open func step<T: MatchedStringRepresentable>(_ expression: String, file: String = #file, line: Int = #line, f: @escaping ([T])->()) {
        self.test.addStep(expression, file: file, line: line) { (matches: [String]) in

            // Convert the matches to the correct type
            var converted = [T]()
            for match in matches {
                guard let convert = T(fromMatch: match) else {
                    XCTFail("Failed to convert \(match) to \(T.self) in \"\(expression)\"")
                    return
                }

                converted.append(convert)
            }

            f(converted)
        }
    }
    
    /**
     If you only want to match the first parameter, this will help make your code nicer
     
     Don't pass anything for file: or path: - these will be automagically filled out for you. Use it like this:
     
         step("Some (regular|irregular) expression") { (match: String) in
             ... some function ...
         }
     
     - parameter expression: The expression to match against
     - parameter f1: The step definition to be run, passing in the first capture group from the expression
     */
    open func step<T: MatchedStringRepresentable>(_ expression: String, file: String = #file, line: Int = #line, f1: @escaping (T)->()) {
        self.test.addStep(expression, file: file, line: line) { (matches: [String]) in
            guard let match = matches.first else {
                XCTFail("Expected single match not found in \"\(expression)\"")
                return
            }

            guard let integer = T(fromMatch: match) else {
                XCTFail("Could not convert \"\(match)\" to \(T.self)")
                return
            }

            f1(integer)
        }
    }
    
    /**
     If you only want to match the first two parameters, this will help make your code nicer
     
     Don't pass anything for file: or path: - these will be automagically filled out for you. Use it like this:
     
         step("Some (regular|irregular) expression with a second capture group here (.*)") { (match1: String, match2: Int) in
             ... some function ...
         }
     
     - parameter expression: The expression to match against
     - parameter f2: The step definition to be run, passing in the first two capture groups from the expression
     */
    open func step<T: MatchedStringRepresentable, U: MatchedStringRepresentable>(_ expression: String, file: String = #file, line: Int = #line, f2: @escaping (T, U)->()) {
        self.test.addStep(expression, file: file, line: line) { (matches: [String]) in
            
            guard matches.count >= 2 else {
                XCTFail("Expected at least 2 matches, found \(matches.count) instead, from \"\(expression)\"")
                return
            }

            guard let i1 = T(fromMatch: matches[0]) else {
                XCTFail("Could not convert '\(matches[0])' to \(T.self), from \"\(expression)\"")
                return
            }

            guard let i2 = U(fromMatch: matches[1]) else {
                XCTFail("Could not convert '\(matches[1])' to \(U.self), from \"\(expression)\"")
                return
            }
            
            f2(i1, i2)
        }
    }

    /**
     Run other steps from inside your overridden defineSteps() method.
     
     Just do:
     
         step("Some Other Step")
     
     - parameter expression: A string which should match another step definition's regular expression

     */
    open func step(_ expression: String) {
        self.test.performStep(expression)
    }
}
