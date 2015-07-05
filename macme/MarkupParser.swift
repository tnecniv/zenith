//
//  MarkupParser.swift
//  macme
//
//  Created by Vincent Pacelli on 7/4/15.
//  Copyright (c) 2015 tnecniv. All rights reserved.
//

import Cocoa

enum ParserState {
    case Normal, OpenTag, Arguments, TaggedText, CloseTag, Escape
}

enum TagType {
    case Color
}

enum TagArg {
    case Red, Blue
}

struct Tag {
    var type: TagType
    var args: [TagArg]
}

class MarkupParser: NSObject {
    var markedText: String = ""
    var unmarkedText: String = ""
    var state: ParserState = .Normal
    var ranges: [NSRange] = []
    var tags: [Tag] = []
    
    init(markedText: String) {
        super.init()
        
        self.markedText = markedText
        parseText()
    }
    
    func parseText() {
        var type: TagType = .Color
        var arg: TagArg = .Red
        var rangeBegin: Int = 0
        var rangeEnd: Int = 0
        
        for i in 0...(count(markedText) - 1) {
            var c = markedText[advance(markedText.startIndex, i)]
            
            switch state {
            case .Normal:
                if c == "\\" {
                    state = .Escape
                } else if c == "<" {
                    state = .OpenTag
                } else {
                    unmarkedText.append(c);
                }
            case .OpenTag:
                if c == "c" {
                    type = .Color
                }
                
                state = .Arguments
            case .Arguments:
                if c == " " {
                    continue
                } else if c == "r" {
                    arg = .Red
                } else if c == "b" {
                    arg = .Blue
                } else if c == ">" {
                    state = .TaggedText
                    rangeBegin = count(unmarkedText)
                } else {
                    
                }
                
            case .TaggedText:
                if c == "<" {
                    rangeEnd = count(unmarkedText)
                    ranges.append(NSMakeRange(rangeBegin, rangeEnd - rangeBegin))
                    tags += [Tag(type: .Color, args: [arg])]
                    state = .CloseTag
                } else {
                    unmarkedText.append(c)
                }
            case .CloseTag:
                if c == ">" {
                    state = .Normal;
                }
            case .Escape:
                unmarkedText.append(c)
            default:
                assert(false, "Bad Parse State");
            }
        }
    }
}
