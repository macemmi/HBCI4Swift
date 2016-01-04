//
//  HBCISyntax.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 18.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

enum HBCIChar: CChar {
    case plus = 0x2B
    case dpoint = 0x3A
    case qmark = 0x3F
    case quote = 0x27
    case amper = 0x40
}

let HBCIChar_plus:CChar = 0x2B
let HBCIChar_dpoint:CChar = 0x3A
let HBCIChar_qmark:CChar = 0x3F
let HBCIChar_quote:CChar = 0x27
let HBCIChar_amper:CChar = 0x40

var syntaxVersions = Dictionary<String,HBCISyntax>();


extension NSXMLElement {
    func valueForAttribute(name: String)->String? {
        let attrNode = self.attributeForName(name)
        if attrNode != nil {
            return attrNode!.stringValue
        }
        return nil
    }
}

class HBCISyntax {
    var document: NSXMLDocument!                    // todo: change to let once Xcode bug is fixed
    var degs: Dictionary<String, HBCIDataElementGroupDescription> = [:]
    var segs: Dictionary<String, HBCISegmentVersions> = [:]
    var codes: Dictionary<String, HBCISegmentVersions> = [:]
    var msgs: Dictionary<String, HBCISyntaxElementDescription> = [:]
    
    init(path: String) throws {
        var xmlDoc: NSXMLDocument?
        let furl = NSURL.fileURLWithPath(path);
        xmlDoc = try NSXMLDocument(contentsOfURL: furl, options:Int(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA));
        
        if xmlDoc == nil {
            xmlDoc = try NSXMLDocument(contentsOfURL: furl, options: Int(NSXMLDocumentTidyXML));
        }
        if xmlDoc == nil {
            logError("HBCI syntax file not found at path \(path)");
            throw HBCIError.SyntaxFileError;
        } else {
            document = xmlDoc!;
        }
        
        try buildDegs();
        try buildSegs();
        try buildMsgs();
    }
    
    func buildDegs() throws {
        if let root = document.rootElement() {
            if let degs = root.elementsForName("DEGs").first {
                for deg in degs.elementsForName("DEGdef") {
                    if let identifier = deg.valueForAttribute("id") {
                        let elem = try HBCIDataElementGroupDescription(syntax: self, element: deg);
                        elem.syntaxElement = deg;
                        self.degs[identifier] = elem;
                    } else {
                        // syntax error
                        logError("Syntax file error: invalid DEGdef element found");
                        throw HBCIError.SyntaxFileError;
                    }
                }
                return;
            } else {
                // error
                logError("Syntax file error: DEGs element not found");
                throw HBCIError.SyntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.SyntaxFileError;
        }
    }
    
    func buildSegs() throws {
        if let root = document.rootElement() {
            if let segs = root.elementsForName("SEGs").first {
                for seg in segs.elementsForName("SEGdef") {
                    let segv = try HBCISegmentVersions(syntax: self, element: seg);
                    self.segs[segv.identifier] = segv;
                    self.codes[segv.code] = segv;
                }
                return;
            } else {
                // error
                logError("Syntax file error: SEGs element not found");
                throw HBCIError.SyntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.SyntaxFileError;
        }
    }
    
    func buildMsgs() throws {
        if let root = document.rootElement() {
            if let msgs = root.elementsForName("MSGs").first {
                for msg in msgs.elementsForName("MSGdef") {
                    if let identifier = msg.valueForAttribute("id") {
                        let elem = try HBCIMessageDescription(syntax: self, element: msg);
                        elem.syntaxElement = msg;
                        self.msgs[identifier] = elem;
                    }
                }
                return;
            } else {
                // error
                logError("Syntax file error: MSGs element not found");
                throw HBCIError.SyntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.SyntaxFileError;
        }
    }
    
    func parseSegment(segData:NSData, binaries:Array<NSData>) throws ->HBCISegment? {
        if let headerDescr = self.degs["SegHead"] {
            if let headerData = headerDescr.parse(UnsafePointer<CChar>(segData.bytes), length: segData.length, binaries: binaries) {
                if let code = headerData.elementValueForPath("code") as? String {
                    if let version = headerData.elementValueForPath("version") as? Int {
                        if let segVersion = self.codes[code] {
                            if let segDescr = segVersion.segmentWithVersion(version) {
                                if let seg = segDescr.parse(segData, binaries: binaries) {
                                    return seg;
                                } else {
                                    throw HBCIError.ParseError;
                                }
                            }
                        }
                        return nil;  // code and/or version are not supported, just continue
                    }
                }
            }
            logError("Parse error: segment code or segment version could not be determined");
            throw HBCIError.ParseError;
        } else {
            logError("Syntax file error: segment SegHead is missing");
            throw HBCIError.SyntaxFileError;
        }
    }
    
    func customMessageForSegment(segName:String, user:HBCIUser) ->HBCIMessage? {
        if let md = self.msgs["CustomMsg"] {
            if let msg = md.compose() as? HBCIMessage {
                if let segVersions = self.segs[segName] {
                    // now find the right segment version
                    // check which segment versions are supported by the bank
                    var supportedVersions = Array<Int>();
                    for seg in user.parameters.bpSegments {
                        if seg.name == segName {
                            // check if this version is also supported by us
                            if segVersions.isVersionSupported(seg.version) {
                                supportedVersions.append(seg.version);
                            }
                        }
                    }
                
                    if supportedVersions.count == 0 {
                        // this process is not supported by the bank
                        logError("Process \(segName) is not supported");
                        return nil;
                    }
                    // now sort the versions - we take the latest supported version
                    supportedVersions.sortInPlace(>);
                    
                    if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                        if let segment = sd.compose() {
                            segment.name = segName;
                            msg.children.insert(segment, atIndex: 2);
                            return msg;
                        }
                    }
                } else {
                    logError("Segment \(segName) is not supported by HBCI4Swift");
                }
            }
        }
        return nil;
    }
    
    class func syntaxWithVersion(version:String) throws ->HBCISyntax {
        if let syntax = syntaxVersions[version] {
            return syntax;
        } else {
            // load syntax
            var path = NSBundle.mainBundle().bundlePath;
            path = path + "/Contents/Frameworks/HBCI4Swift.framework/Resources/hbci\(version).xml";
            let syntax = try HBCISyntax(path: path)
            syntaxVersions[version] = syntax;
            return syntax;
        }
    }
}

