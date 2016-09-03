//
//  HelloPerfectHandler.swift
//  HelloPerfect
//
//  Created by Bhanu Birani on 03/09/16.
//  Copyright © 2016 MB Corp. All rights reserved.
//

import Foundation
import PerfectLib

public func PerfectServerModuleInit() {
    
    Routing.Handler.registerGlobally()
    
    Routing.Routes["GET", ["/", "index.html"]] = { (_: WebResponse) in return IndexHandler() }
    
    
    Routing.Routes["GET", "/foo"] = { (_: WebResponse) in return ServicesHandler() }
    
}

class IndexHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        response.appendBodyString("Hello, Perfect!")
        response.requestCompletedCallback()
        
    }
    
}

class ServicesHandler: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        // encode the random content into JSON
        let jsonEncoder = JSONEncoder()
        
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.stringFromDate(date)
        dateFormatter.dateFormat = "hh:mm:ss"
        let timeString = dateFormatter.stringFromDate(date)
        
        
        do {
            let respString = try jsonEncoder.encode(["title": "This is the json title", "description": "This is json description", "date": dateString, "time": timeString])
            response.appendBodyString(respString)
            response.addHeader("Content-Type", value: "application/json")
            response.setStatus(200, message: "OK")
            
        } catch {
            response.setStatus(400, message: "Bad Request")
            response.appendBodyString("Bad request")
        }
        
        response.requestCompletedCallback()
        
    }
    
}


