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
  
  typealias CharRule = (Character) -> ValidateStringError?
  
  init(with run: @escaping (String) -> [ValidateStringError]) {
    self.run = run
  }
  
  static func createWith(inclusionRules:[ValidateString.CharRule]) -> ValidateString {
    return ValidateString { string in
      var errorDictionary = [ValidateStringError: Int]()
      for char in string {
        for applyRule in inclusionRules {
          guard let error = applyRule(char) else { continue }
          incrementValue(of: &errorDictionary, forKey: error)
        }
      }
      return getKeysFrom(dictionary: errorDictionary, whereValueIs: string.count)
    }
  }
  
  static var signUp: ValidateString {
    return ValidateString(with: hasMinLengthRule)
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
  case maxPasswordLength
  case noSpecialChar
  case noNumber
  case noLowerCase
  case noUpperCase
  case noWhitespace
  case none
  
  var rawValue: String {
    switch self {
    case .passwordLength: return "PASSWORD_LENGTH"
    case .maxPasswordLength: return "MAX_PASSWORD_LENGTH"
    case .noSpecialChar: return "NO_SPECIAL_CHARS"
    case .noNumber: return "NO_NUMBER"
    case .noLowerCase: return "NO_LOWERCASE"
    case .noUpperCase: return "NO_UPPERCASE"
    case .noWhitespace: return "NO_WHITESPACE"
    case .none: return "NONE"
    }
  }
}

func includeUppercase(char: Character) -> ValidateStringError? {
  if !char.isUppercase { return .noUpperCase }
  else { return nil }
}

func includeLowercase(char: Character) -> ValidateStringError? {
  if !char.isLowercase { return .noLowerCase }
  else { return nil }
}

func includeSpecial(char: Character) -> ValidateStringError? {
  let chosenSpecialChars = "/*!@#$%^&*()\"{}_[]|\\?/<>,."
  if !chosenSpecialChars.contains(char) { return .noSpecialChar }
  else { return nil }
}

func includeNumber(char: Character) -> ValidateStringError? {
  if !char.isNumber { return .noNumber }
  else { return nil }
}

func includeWhitespace(char: Character) -> ValidateStringError? {
  if !char.isWhitespace { return .noWhitespace }
  else { return nil }
}

func hasMinLengthRule(_ string: String) -> [ValidateStringError] {
  if string.count < 9 { return [.passwordLength] }
  else { return [] }
}

func hasMaxLengthRule(_ string: String) -> [ValidateStringError] {
  if string.count > 80 { return [.maxPasswordLength] }
  else { return [] }
}

func incrementValue<K>(of dictionary: inout [K: Int], forKey key: K) {
  if let count = dictionary[key] {
    dictionary[key] = count + 1
  } else { dictionary[key] = 1 }
}

func getKeysFrom<K>(dictionary: [K: Int], whereValueIs count: Int) -> [K] {
  var keys = [K]()
  dictionary.forEach({ (key, keyCount) in
    if (keyCount == count) { keys.append(key) }
  })
  return keys
}
