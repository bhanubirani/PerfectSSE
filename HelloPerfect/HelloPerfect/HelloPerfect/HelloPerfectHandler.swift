//
//  HelloPerfectHandler.swift
//  HelloPerfect
//
//  Created by Bhanu Birani on 03/09/16.
//  Copyright © 2016 MB Corp. All rights reserved.
//

import Foundation
import PerfectLib
import MySQL


let HOST = "localhost"
let USERNAME = "root"
let PASSWORD = "password"
let DB_NAME = "PerfectTesting"
let TABLE_NAME = "Messages"


func createDatabase() {
    
    let mysql = MySQL()
    let connected = mysql.connect(HOST, user: USERNAME, password: PASSWORD)
    
    guard connected else { print(mysql.errorMessage()); return }
    
    defer { mysql.close() }
    
    var isDatabase = mysql.selectDatabase(DB_NAME)
    if !isDatabase {
        isDatabase = mysql.query("CREATE DATABASE \(DB_NAME);")
    }
    
    let isTable = mysql.query("CREATE TABLE \(TABLE_NAME) (message TEXT, author TEXT);")
    
    guard isDatabase && isTable else { print(mysql.errorMessage()); return }
    
}

public func PerfectServerModuleInit() {
    
    Routing.Handler.registerGlobally()
    
    // TUTORIAL 1
    Routing.Routes["GET", ["/", "index.html"]] = { (_: WebResponse) in return IndexHandler() }
    Routing.Routes["GET", "/foo"] = { (_: WebResponse) in return ServicesHandler() }
    
    // TUTORIAL 2
    Routing.Routes["GET", "/messages"] = { (_: WebResponse) in return GetAllMessages() }
    Routing.Routes["GET", "/messagesForAuthor"] = { (_: WebResponse) in return GetMessagesForAuthor() }
    Routing.Routes["POST", "/postMessages"] = { _ in return PostMessages() }
    
    createDatabase()
}

func resultsToJSON(results results: MySQL.Results, _ fields: [String]) -> String? {
    
    if results.numFields() != fields.count { return nil }
    
    let encoder = JSONEncoder()
    var rowValues = [[String: JSONValue]]()
    
    results.forEachRow { (row) in
        
        var rowValue = [String: JSONValue]()
        for c in 0 ..< fields.count {
            rowValue[fields[c]] = row[c]
        }
        rowValues.append(rowValue)
    }
    
    var responseString = "["
    
    do {
        for c in 0 ..< rowValues.count {
            let rowJSON = try encoder.encode(rowValues[c])
            responseString += rowJSON
            
            if c != rowValues.count - 1 { responseString += "," }
            else { responseString += "]" }
        }
        return responseString
    } catch {
        return nil
    }
}


class GetAllMessages: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USERNAME, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Coundn't connect to MySQL")
            response.requestCompletedCallback()
            return
        }
        
        mysql.selectDatabase(DB_NAME)
        defer { mysql.close() }
        
        let querySuccess = mysql.query("SELECT * FROM \(TABLE_NAME);")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Things went wrong while querying the table")
            response.requestCompletedCallback()
            return
        }
        
        let results = mysql.storeResults()
        guard (results != nil) else {
            print("No messages found")
            response.setStatus(500, message: "No data found in table")
            response.requestCompletedCallback()
            return
        }
        
        let result = resultsToJSON(results: results!, ["message", "author"])
        guard result != nil else {
            print("JSON encoding failed")
            response.setStatus(500, message: "Oops!! JSON encoding failed..")
            response.requestCompletedCallback()
            return
        }
        
        response.appendBodyString(result!)
        response.setStatus(200, message: "OK")
        response.requestCompletedCallback()
    }
    
}

class GetMessagesForAuthor: RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USERNAME, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Could not connect to MySQL")
            response.requestCompletedCallback()
            return
        }
        
        let author = request.param("author")
        guard author != nil else {
            response.setStatus(400, message: "Please provide valid author name")
            response.requestCompletedCallback()
            return
        }
        
        mysql.selectDatabase(DB_NAME)
        defer { mysql.close() }
        
        let querySuccess = mysql.query("SELECT * FROM \(TABLE_NAME) WHERE author='\(author!)';")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Things went wrong while querying the table")
            response.requestCompletedCallback()
            return
        }
        
        let results = mysql.storeResults()
        guard (results != nil) else {
            print("No messages found")
            response.setStatus(500, message: "No data found in table")
            response.requestCompletedCallback()
            return
        }
        
        let result = resultsToJSON(results: results!, ["message", "author"])
        guard result != nil else {
            print("JSON encoding failed")
            response.setStatus(500, message: "Oops!! JSON encoding failed..")
            response.requestCompletedCallback()
            return
        }
        
        response.appendBodyString(result!)
        response.setStatus(200, message: "OK")
        response.requestCompletedCallback()
        
    }
}

class PostMessages : RequestHandler {
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        let params = request.postParams
        guard params.count == 2 else {
            response.setStatus(400, message: "Invalid params")
            response.requestCompletedCallback(); return
        }
        
        let message = params[0].1
        let author = params[1].1
        
        let mysql = MySQL()
        let connected = mysql.connect(HOST, user: USERNAME, password: PASSWORD)
        
        guard connected else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Could not connect to MySQL")
            response.requestCompletedCallback()
            return
        }
        
        let isDatabase = mysql.selectDatabase(DB_NAME)
        guard isDatabase else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Things went wrong while selecting database")
            response.requestCompletedCallback()
            return
        }
        
        let querySuccess = mysql.query("INSERT INTO \(TABLE_NAME) (message, author) VALUES ('\(message)', '\(author)')")
        guard querySuccess else {
            print(mysql.errorMessage())
            response.setStatus(500, message: "Things went wrong while querying the table")
            response.requestCompletedCallback()
            return
        }
        
        
        response.setStatus(200, message: "OK")
        response.requestCompletedCallback()
    }
    
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

