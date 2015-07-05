//
//  TestViewController.swift
//  macme
//
//  Created by Vincent Pacelli on 7/3/15.
//  Copyright (c) 2015 tnecniv. All rights reserved.
//

import Cocoa

class TestViewController: NSViewController {
    
    @IBOutlet var text: NSTextView!
    var task: NSTask = NSTask()
    var inPipe: NSPipe = NSPipe()
    var outPipe: NSPipe = NSPipe()
    var inHandle: NSFileHandle = NSFileHandle()
    var outHandle: NSFileHandle = NSFileHandle()
    var p = MarkupParser(markedText: "Foo <c r>bar</c> baz")

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task.currentDirectoryPath = "~"
        task.launchPath = "/bin/bash"
        task.arguments = ["-i"]
        //task.arguments = ["/Users/tnecniv/.vimrc"]
        task.standardOutput = inPipe
        task.standardInput = outPipe
        inHandle = inPipe.fileHandleForReading
        outHandle = outPipe.fileHandleForWriting
        task.launch()
        
        outHandle.writeData(("echo poop\r\n" as NSString).dataUsingEncoding(NSASCIIStringEncoding)!)
        outHandle.writeData(("echo butts\r\n" as NSString).dataUsingEncoding(NSASCIIStringEncoding)!)
        //outHandle.closeFile()
        
    }
    
    func spawnProcess(path: String, args: [String], dir: String) -> (NSTask, NSFileHandle, NSFileHandle) {
        var t = NSTask()
        var pi = NSPipe()
        var po = NSPipe()
        t.currentDirectoryPath = dir
        t.launchPath = path
        t.arguments = args
        t.standardInput = pi
        t.standardOutput = po
        t.launch()
        
        return (t, pi.fileHandleForReading, po.fileHandleForWriting)
    }
    
    @IBAction func clicked(sender: NSButton) {
        
        //text.insertText(NSString(data: inHandle.readDataOfLength(1), encoding:NSUTF8StringEncoding) as! String)
        text.string = p.unmarkedText
        text.setTextColor(NSColor.redColor(), range: p.ranges[0])
        
    }
    
    
}
