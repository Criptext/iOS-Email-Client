//
//  ValidateStringTests.swift
//  iOS-Email-ClientTests
//
//  Created by robjaq on 9/18/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import XCTest
@testable import iOS_Email_Client

class ValidateStringTests: XCTestCase {
  
  func testUppercaseReturnsNil() {
    let char: Character = "A"
    
    let error = includeUppercase(char: char)
    
    XCTAssertEqual(error, nil, "Any uppercase char must always return nil")
  }
  
  func testNoUppercaseReturnsError() {
    let char: Character = "$"
    
    let error = includeUppercase(char: char)
    
    XCTAssertEqual(error, .noUpperCase, "Any non uppercase char must return the noUppercase error")
  }
  
  func testLowercaseReturnsNil() {
    let char: Character = "a"
    
    let error = includeLowercase(char: char)
    
    XCTAssertEqual(error, nil, "Any lowercase char must always return nil")
  }
  
  func testNoLowercaseReturnsError() {
    let char: Character = "$"
    
    let error = includeLowercase(char: char)
    
    XCTAssertEqual(error, .noLowerCase, "Any non lowercase char must return the noLowerCase error")
  }
  
  func testSpecialCharReturnsNil() {
    let char: Character = "$"
    
    let error = includeSpecial(char: char)
    
    XCTAssertEqual(error, nil, "Any specified special char must always return nil")
  }
  
  func testNoSpecialCharReturnsError() {
    let char: Character = "a"
    
    let error = includeSpecial(char: char)
    
    XCTAssertEqual(error, .noSpecialChar, "Any non special char must always return the noSpecialChar error")
  }
  
  func testNumberReturnsNil() {
    let char: Character = "7"
    
    let error = includeNumber(char: char)
    
    XCTAssertEqual(error, nil, "Any number char must always return nil")
  }
  
  func testNoNumberReturnsError() {
    let char: Character = "a"
    
    let error = includeNumber(char: char)
    
    XCTAssertEqual(error, .noNumber, "Any non number char must always return the noNumber error")
  }
  
  func testWhitepspaceReturnsNil() {
    let char: Character = " "
    
    let error = includeWhitespace(char: char)
    
    XCTAssertEqual(error, nil, "Whitespace char must always return nil")
  }
  
  func testNoWhitespaceReturnsError() {
    let char: Character = "a"
    
    let error = includeWhitespace(char: char)
    
    XCTAssertEqual(error, .noWhitespace, "Any non whitespace char must always return the noWhitespace error")
  }
  
  func testStringCountAboveMaxLengthReturnsError() {
    let error = hasMaxLengthRule(getStringWith(count: 81))
    
    XCTAssertEqual(error, [.maxPasswordLength])
  }
  
  func testStringCountBelowMaxLengthReturnsEmptyCollection() {
    let error = hasMaxLengthRule(getStringWith(count: 79))
    
    XCTAssertEqual(error, [])
  }
  
  func testStringCountAboveMinLengthReturnsEmptyCollection() {
    let error = hasMinLengthRule(getStringWith(count: 56))
    
    XCTAssertEqual(error, [])
  }
  
  func testStringCountBelowMinLengthReturnsError() {
    let error = hasMinLengthRule(getStringWith(count: 3))
    
    XCTAssertEqual(error, [.passwordLength])
  }
  
  func testValidatorWithInclusionCharRulesReturnsEmptyCollection() {
    let sut = ValidateString.createWith(inclusionRules: [includeWhitespace,
                                                         includeSpecial,
                                                         includeLowercase,
                                                         includeUppercase,
                                                         includeNumber])
    let str = " @bA8"
    let errors = sut.run(str)
    
    XCTAssertEqual(errors, [])
  }
  
  func testCreatingValidatorWithInclusionCharRulesReturnsCollectionOfErrors() {
    let sut = ValidateString.createWith(inclusionRules: [includeWhitespace,
                                                         includeSpecial,
                                                         includeLowercase,
                                                         includeUppercase,
                                                         includeNumber])
    let str = "aaaabbbbA8"
    let errors = sut.run(str)
    
    XCTAssertTrue(errors.fuzzyMatches(other: [.noSpecialChar, .noWhitespace]))
  }
  
  func testZippingValidatorsReturnsValidatorIncludingBothRules() {
    let validator1 = ValidateString(with: hasMinLengthRule)
    let validator2 = ValidateString(with: hasMaxLengthRule)
    let sut = zip(validator1, validator2)
    
    let errors = sut.run(getStringWith(count: 7))
    XCTAssertEqual(errors, [.passwordLength])
    
    let noErrors = sut.run(getStringWith(count: 18))
    XCTAssertEqual(noErrors, [])
    
    let errors2 = sut.run(getStringWith(count: 90))
    XCTAssertEqual(errors2, [.maxPasswordLength])
  }
  
  func testIncrementOfDictionaryValueForKey() {
    var dict = [String: Int]()
    let key = "key"
    dict[key] = 1
    
    incrementValue(of: &dict, forKey: key)
    
    XCTAssertEqual(dict[key], 2)
  }
  
  func testArrayErrorOrderMatchesOrderOfZipInputs() {
    let validator1 = ValidateString(with: hasMinLengthRule)
    let validator2 = ValidateString.createWith(inclusionRules: [includeLowercase, includeSpecial])
    
    let zipped = zip(validator1, validator2)
    let errors = zipped.run(getStringWith(count: 7))
    let sut = errors.first
    
    XCTAssertEqual(sut, ValidateStringError.passwordLength)
  }
  
  func testGetKeysFromDictionaryWithAValueOf14() {
    let stub = createStubDictionary()
    
    let keys = getKeysFrom(dictionary: stub, whereValueIs: 14)
    
    XCTAssertTrue(keys.fuzzyMatches(other: ["key1", "key4", "key5"]))
  }
  
  func createStubDictionary() -> [String: Int] {
    var dict = [String: Int]()
    let value = 14
    dict["key1"] = value
    dict["key2"] = 24
    dict["key3"] = 35
    dict["key4"] = value
    dict["key5"] = value
    return dict
  }
  
  func getStringWith(count: Int) -> String {
    guard count > 0 else { return "" }
    var str = ""
    for _ in 0..<count { str.append("a") }
    return str
  }
  
  // MARK: Issues
  func testValidatorReturnsEmptyWithDuplicateCharRules() {
    let sut = ValidateString.createWith(inclusionRules: [includeWhitespace,
                                                         includeWhitespace])
    let noWhiteSpace = "f%dfdsdsdf"
    let errors = sut.run(noWhiteSpace)
    
    XCTAssertEqual(errors, []) // no error included
  }
  
  func testEmptyStringWithInclusionCharRulesReturnsEmptyCollection() {
    let sut = ValidateString.createWith(inclusionRules: [includeWhitespace,
                                                         includeSpecial,
                                                         includeLowercase,
                                                         includeUppercase,
                                                         includeNumber])
    let emptyStr = ""
    let errors = sut.run(emptyStr)
    
    XCTAssertEqual(errors, [])
  }
}

extension Array where Element: Equatable {
  func fuzzyMatches(other: Array) -> Bool {
    guard self.count == other.count else {
      return false
    }
    
    var selfCopy = self
    
    for item in other {
      if let index =
        selfCopy.firstIndex(of: item) {
        selfCopy.remove(at: index)
      } else {
        return false
      }
    }
    
    return true
  }
}

extension Array where Element: Comparable {
  func fuzzyMatches(other: Array) -> Bool {
    let sortedSelf = self.sorted()
    let sortedOther = other.sorted()
    return sortedSelf == sortedOther
  }
}
