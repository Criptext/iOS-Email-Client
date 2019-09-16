//
//  ValidateString.swift
//  iOS-Email-Client
//
//  Created by robjaq on 9/15/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

struct ValidateString {
  let run: (String) -> [ValidateStringError]
  
  init(with run: @escaping (String) -> [ValidateStringError]) {
    self.run = run
  }
}

func zip(_ a: ValidateString, _ b: ValidateString) -> ValidateString {
  return ValidateString { string -> [ValidateStringError] in
    let errorsA = a.run(string)
    let errorsB = b.run(string)
    return errorsA + errorsB
  }
}

enum ValidateStringError: Error {
  case passwordLength
  case noSpecialChar
  case noNumber
  case noLowerCase
  case noUpperCase
  case noWhitespace
  case none
  
  var rawValue: String {
    switch self {
    case .passwordLength: return "PASSWORD_LENGTH"
    case .noSpecialChar: return "NO_SPECIAL_CHARS"
    case .noNumber: return "NO_NUMBER"
    case .noLowerCase: return "NO_LOWERCASE"
    case .noUpperCase: return "NO_UPPERCASE"
    case .noWhitespace: return "NO_WHITESPACE"
    case .none: return "NONE"
    }
  }
}

typealias hasCharRule = (Character) -> ValidateStringError?

func hasUppercase(char: Character) -> ValidateStringError? {
  if !char.isUppercase { return .noUpperCase }
  else { return nil }
}

func hasLowercase(char: Character) -> ValidateStringError? {
  if !char.isLowercase { return .noLowerCase }
  else { return nil }
}

func hasSpecial(char: Character) -> ValidateStringError? {
  let chosenSpecialChars = "/*!@#$%^&*()\"{}_[]|\\?/<>,."
  if !chosenSpecialChars.contains(char) { return .noSpecialChar }
  else { return nil }
}

func hasNumber(char: Character) -> ValidateStringError? {
  if !char.isNumber { return .noNumber }
  else { return nil }
}

func hasMinLengthRule(_ string: String) -> [ValidateStringError] {
  if string.count < Constants.MinCharactersPassword { return [.passwordLength] }
  else { return [] }
}

func hasMaxLengthRule(_ string: String) -> [ValidateStringError] {
  if string.count > 80 { return [.passwordLength] }
  else { return [] }
}

func hasWhiteSpace(char: Character) -> ValidateStringError? {
  if !char.isWhitespace { return .noWhitespace }
  else { return nil }
}

func apply(rules: [hasCharRule]) -> (String) -> [ValidateStringError] {
  return { string in
    var errorDictionary = [ValidateStringError: Int]()
    for char in string {
      for applyRule in rules {
        if let error = applyRule(char) {
          update(dictionary: &errorDictionary, with: error)
        }
      }
    }
    return getValidErrorsFrom(dictionary: errorDictionary, matching: string.count)
  }
}

fileprivate func update(dictionary: inout [ValidateStringError: Int], with error: ValidateStringError) {
  if let errorCount = dictionary[error] {
    dictionary[error] = errorCount + 1
  } else { dictionary[error] = 1 }
}

fileprivate func getValidErrorsFrom(dictionary: [ValidateStringError: Int], matching count: Int) -> [ValidateStringError] {
  var errors = [ValidateStringError]()
  dictionary.forEach({ (error, errorCount) in
    if (errorCount == count) {
      errors.append(error)
    }
  })
  return errors
}

struct Validators {
  static func createSignUp() -> ValidateString {
//    let signUpCharRules = apply(rules: [hasUppercase,
//                                        hasLowercase,
//                                        hasSpecial,
//                                        hasNumber])
    
//    let signUpValidator = zip(ValidateString(with: signUpCharRules),
//                              ValidateString(with: hasMinLengthRule))
    
    let signUpValidator = ValidateString(with: hasMinLengthRule)
    return signUpValidator
  }
  
  static func alwaysSuccess() -> ValidateString {
    return ValidateString { _ in
      return []
    }
  }
  
  static func neverSuccess() -> ValidateString {
    return ValidateString { _ in
      return [.none]
    }
  }
}

