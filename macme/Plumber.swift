//
//  Plumber.swift
//  macme
//
//  Created by Vincent Pacelli on 7/5/15.
//  Copyright (c) 2015 tnecniv. All rights reserved.
//

import Cocoa
import Foundation

struct PlumberMessage {
    var src: String = ""
    var dst: String = ""
    var wdir: String = ""
    var type: String = ""
    var attr: Dictionary<String, String> = Dictionary()
    var data: [UInt8] = []
}

enum PlumberLexResult {
    case Definition(String, String)
    case Rule(String, String, String)
    case Include(String)
    case Error(String?)
}

enum PlumbResult {
    case Error(String?)
    case Start(String)
    case Client(String)
    case None
}

func ==(a: PlumbResult, b: PlumbResult) -> Bool {
    switch (a, b) {
    case (.Error(let s1), .Error(let s2)):
        return s1 == s2
    case (.Start(let s1), .Start(let s2)):
        return s1 == s2
    case (.Client(let s1), .Client(let s2)):
        return s1 == s2
    case (.None, .None):
        return true
    default:
        return false
    }
}

func !=(a: PlumbResult, b: PlumbResult) -> Bool {
    return !(a == b)
}

class Plumber {
    var plumbFileContent: String = "";
    var lines: [String] = []
    var fileMgr: NSFileManager = NSFileManager()
    var lastCaptureGroup: Int = 0
    
    init() {
    }
    
    init(path: String) {
        loadFile(path)
    }
    
    func loadFile(path: String) {
        var error: NSError?
        var content: String = NSString(contentsOfFile: path.stringByExpandingTildeInPath, encoding: NSASCIIStringEncoding, error: nil) as! String
        lines = split(content, allowEmptySlices: true, isSeparator: {(c: Character) -> Bool in return c == "\n" })
    }
    
    func lex(line: String) -> PlumberLexResult {
        var first: String = ""
        var second: String = ""
        var rest: String = ""
        var mode: Int = 0;
        var eatWhitespace: Bool = true
        var error: String = ""
        
        for c in Range(start: line.unicodeScalars.startIndex, end: line.unicodeScalars.endIndex) {
            switch mode {
            case 0:
                if NSCharacterSet.whitespaceCharacterSet().longCharacterIsMember(line.unicodeScalars[c].value) {
                    if eatWhitespace {
                        continue
                    } else {
                        eatWhitespace = true
                        mode = 1;
                    }
                } else if line.unicodeScalars[c] == "=" {
                    var value: String = ""
                    
                    for x in Range(start: c.successor(), end: line.unicodeScalars.endIndex) {
                        value.append(line.unicodeScalars[x])
                    }
                    
                    return .Definition(first, value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
                } else {
                    eatWhitespace = false
                    first.append(line.unicodeScalars[c])
                }
            case 1:
                if NSCharacterSet.whitespaceCharacterSet().longCharacterIsMember(line.unicodeScalars[c].value) {
                    if eatWhitespace {
                        continue
                    } else {
                        eatWhitespace = true
                        mode = 2
                    }
                } else {
                    eatWhitespace = false
                    second.append(line.unicodeScalars[c])
                }
            case 2:
                rest.append(line.unicodeScalars[c])
            default:
                return .Error(error)
            }
        }
        
        if first == "" || second == "" {
            return .Error("Line incomplete")
        } else if first == "include" {
            return .Include(second + rest)
        } else if rest == "" {
            return .Error("Expected argument")
        } else {
            return .Rule(first, second, rest)
        }
    }
    
    func evalArg(s: String, defs: Dictionary<String, String>) -> String {
        var singleQuote: Bool = false
        var doubleQuote: Bool = false
        var variable: Bool = false
        var escape: Bool = false
        var ret: String = ""
        var variableName: String = ""
        var alphanum = NSCharacterSet.alphanumericCharacterSet();
        
        for c in s.unicodeScalars {
            if c == "'" {
                if doubleQuote {
                    ret.append(c)
                } else if escape {
                    ret.append(c)
                    escape = false
                } else {
                    singleQuote = !singleQuote
                }
            } else if c == "\"" {
                if singleQuote {
                    ret.append(c)
                } else if escape {
                    ret.append(c)
                    escape = false
                } else {
                    doubleQuote = !doubleQuote
                }
            } else if c == "\\" {
                if escape {
                    ret.append(c)
                    escape = false
                } else if singleQuote {
                    ret.append(c)
                } else {
                    escape = true
                }
            } else if c == "$" {
                if escape {
                    ret.append(c)
                } else if singleQuote {
                    ret.append(c)
                } else if variable {
                    if let val = defs[variableName] {
                        ret += val
                    } else {
                        
                    }
                    
                    variableName = String(c);
                } else {
                    variable = true;
                    variableName = String(c);
                }
            } else {
                if variable && alphanum.longCharacterIsMember(c.value) {
                    variableName.append(c)
                } else if variable && !alphanum.longCharacterIsMember(c.value) {
                    variable = false
                    
                    if let val = defs[variableName] {
                        ret += val
                    } else {
                        ret += "" // Shell doesnt error on undefs, they are just empty
                    }
                    
                    ret.append(c)
                } else {
                    ret.append(c)
                }
            }
        }
        
        if (variable) {
            if let val = defs[variableName] {
                ret += val
            } else {
                
            }
        }
        
        return ret;
    }
    
    func plumb(message: PlumberMessage) -> PlumbResult {
        var defs: Dictionary<String, String> = Dictionary<String, String>()
        var badParse: Bool = false
        var skipRule: Bool = false
        var lineNum: Int = 0
        var action: PlumbResult = .None
        var msg = message
        
        for line in lines {
            lineNum = lineNum + 1
            
            if line.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == ""
                || line[line.startIndex] == "#" {
                    if !skipRule && action != .None {
                        return action
                    } else {
                        skipRule = false
                        msg = message // Reset for next rule
                        action = .None
                        
                        continue
                    }
            }
            
            var lexResult = lex(line)
            
            switch (lexResult) {
            case .Definition(let name, let value):
                defs["$" + name] = evalArg(value, defs: defs)
            case .Include(let path):
                print("nop")
            case .Rule(let first, let second, let third):
                var eThird = evalArg(third, defs: defs)
                
                if second == "is" {
                    if first == "src" {
                        skipRule = !(msg.src == eThird)
                    } else if first == "dst" {
                        skipRule = !(msg.dst == eThird)
                    } else if first == "wdir" {
                        skipRule = !(msg.wdir == eThird)
                    } else if first == "type" {
                        skipRule = !(msg.type == eThird)
                    } else if first == "ndata" {
                        skipRule = !(count(msg.data) == eThird.toInt())
                    } else if first == "data" {
                        skipRule = !(msg.data == ([UInt8](eThird.utf8)))
                    } else {
                        return .Error(String(lineNum) + ": Expected object as first word")
                    }
                } else if second == "isdir" {
                    var isDir: ObjCBool = false
                    var dir: String = ""
                    var exists: Bool = false
                    
                    if first == "src" {
                        dir = msg.src
                    } else if first == "dst" {
                        dir = msg.dst
                    } else if first == "wdir" {
                        dir = msg.wdir
                    } else if first == "type" {
                        dir = msg.type
                    } else if first == "ndata" {
                        dir = String(count(msg.data))
                    } else if first == "data" {
                        dir = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                    } else if first == "arg" {
                        dir = eThird
                    } else {
                        return .Error(String(lineNum) + ": Expected object as first word")
                    }
                    
                    if first == "arg" {
                        exists = fileMgr.fileExistsAtPath(dir.stringByExpandingTildeInPath, isDirectory: &isDir)
                    } else {
                        exists = fileMgr.fileExistsAtPath(eThird + "/" + dir.stringByExpandingTildeInPath, isDirectory: &isDir)
                    }
                    
                    skipRule = !(exists && isDir)
                    
                    if !skipRule {
                        defs["$dir"] = eThird
                    }
                } else if second == "isfile" {
                    var file: String = ""
                    var exists: Bool = false
                    var isDir: ObjCBool = false
                    
                    if first == "src" {
                        file = msg.src
                    } else if first == "dst" {
                        file = msg.dst
                    } else if first == "wdir" {
                        file = msg.wdir
                    } else if first == "type" {
                        file = msg.type
                    } else if first == "ndata" {
                        file = String(count(msg.data))
                    } else if first == "data" {
                        file = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                    } else if first == "arg" {
                        file = eThird
                    } else {
                        return .Error(String(lineNum) + ": Expected object as first word")
                    }
                    
                    if first == "arg" {
                        exists = fileMgr.fileExistsAtPath(file.stringByExpandingTildeInPath, isDirectory: &isDir)
                    } else {
                        exists = fileMgr.fileExistsAtPath(eThird + "/" + file.stringByExpandingTildeInPath, isDirectory: &isDir)
                    }
                    
                    skipRule = !(exists && !isDir)
                    
                    if !skipRule {
                        defs["$file"] = eThird
                    }
                } else if second == "matches" {
                    var str: String = ""
                    
                    if first == "src" {
                        str = msg.src
                    } else if first == "dst" {
                        str = msg.dst
                    } else if first == "wdir" {
                        str = msg.wdir
                    } else if first == "type" {
                        str = msg.type
                    } else if first == "ndata" {
                        str = String(count(msg.data))
                    } else if first == "data" {
                        str = NSString(bytes: msg.data, length: count(msg.data), encoding: NSUTF8StringEncoding) as! String
                    } else {
                        return .Error(String(lineNum) + ": Expected object as first word")
                    }
                    
                    var r = Regex(eThird)
                    
                    skipRule = !r.test(str)
                    
                    if !skipRule {
                        lastCaptureGroup = count(r.captureGroups) - 1
                        
                        for i in 0...lastCaptureGroup {
                            defs["$" + String(i)] = r.captureGroups[i]
                        }
                    }
                } else if second == "set" {
                    if first == "src" {
                        msg.src = eThird
                    } else if first == "dst" {
                        msg.dst = eThird
                    } else if first == "wdir" {
                        msg.dst = eThird
                    } else if first == "type" {
                        msg.dst = eThird
                    } else if first == "data" {
                        msg.data = [UInt8](eThird.utf8)
                    } else {
                        return .Error(String(lineNum) + ": Expected object as first word")
                    }
                } else if second == "to" {
                    if first != "plumb" { return .Error(String(lineNum) + ": Expected `plumb' as first word") }
                    else if msg.dst != eThird { skipRule = true }
                } else if second == "client" {
                    if first != "plumb" { return .Error(String(lineNum) + ": Expected `plumb' as first word") }
                    else if action != PlumbResult.None { return .Error(String(lineNum) + ": Cannont have a second action in rule") }
                    else { action = .Client(eThird) }
                } else if second == "start" {
                    if first != "plumb" { return .Error(String(lineNum) + ": Expected `plumb' as first word") }
                    else if action != PlumbResult.None { return .Error(String(lineNum) + ": Cannont have a second action in rule") }
                    else { action = .Start(eThird) }
                } else {
                    return .Error(String(lineNum) + ": Expected action as second word")
                }
            case .Error(let errorText):
                return .Error(errorText)
            }

        }
        
        return action
    }
}
