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
    var pipe: NSPipe = NSPipe()
    var handle: NSFileHandle = NSFileHandle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task.currentDirectoryPath = "~"
        task.launchPath = "/bin/echo"
        task.standardOutput = pipe;
        task.launch();
        handle = pipe.fileHandleForReading;
    }
    
    @IBAction func clicked(sender: NSButton) {
        text.string = NSString(data: handle.readDataOfLength(1), encoding:NSUTF8StringEncoding) as? String
        
    }
    
    
}
