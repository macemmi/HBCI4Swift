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


extension XMLElement {
    func valueForAttribute(_ name: String)->String? {
        let attrNode = self.attribute(forName: name)
        if attrNode != nil {
            return attrNode!.stringValue
        }
        return nil
    }
}

class HBCISyntax {
    var document: XMLDocument!                    // todo: change to let once Xcode bug is fixed
    var degs: Dictionary<String, HBCIDataElementGroupDescription> = [:]
    var segs: Dictionary<String, HBCISegmentVersions> = [:]
    var codes: Dictionary<String, HBCISegmentVersions> = [:]
    var msgs: Dictionary<String, HBCISyntaxElementDescription> = [:]
    
    init(path: String) throws {
        var xmlDoc: XMLDocument?
        let furl = URL(fileURLWithPath: path);
        do {
            xmlDoc = try XMLDocument(contentsOf: furl, options:XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLNode.Options.nodePreserveWhitespace.rawValue|XMLNode.Options.nodePreserveCDATA.rawValue))));
            
            if xmlDoc == nil {
                xmlDoc = try XMLDocument(contentsOf: furl, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(XMLDocument.Options.documentTidyXML.rawValue))));
            }
        }
        catch let err as NSError {
            logError("HBCI Syntax file error: \(err.localizedDescription)");
            logError("HBCI syntax file issue at path \(path)");
            throw HBCIError.syntaxFileError;
        }

        if xmlDoc == nil {
            logError("HBCI syntax file not found (xmlDoc=nil) at path \(path)");
            throw HBCIError.syntaxFileError;
        } else {
            document = xmlDoc!;
        }
        
        try buildDegs();
        try buildSegs();
        try buildMsgs();
    }
    
    func buildDegs() throws {
        if let root = document.rootElement() {
            if let degs = root.elements(forName: "DEGs").first {
                for deg in degs.elements(forName: "DEGdef") {
                    if let identifier = deg.valueForAttribute("id") {
                        let elem = try HBCIDataElementGroupDescription(syntax: self, element: deg);
                        elem.syntaxElement = deg;
                        self.degs[identifier] = elem;
                    } else {
                        // syntax error
                        logError("Syntax file error: invalid DEGdef element found");
                        throw HBCIError.syntaxFileError;
                    }
                }
                return;
            } else {
                // error
                logError("Syntax file error: DEGs element not found");
                throw HBCIError.syntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.syntaxFileError;
        }
    }
    
    func buildSegs() throws {
        if let root = document.rootElement() {
            if let segs = root.elements(forName: "SEGs").first {
                for seg in segs.elements(forName: "SEGdef") {
                    let segv = try HBCISegmentVersions(syntax: self, element: seg);
                    self.segs[segv.identifier] = segv;
                    self.codes[segv.code] = segv;
                }
                return;
            } else {
                // error
                logError("Syntax file error: SEGs element not found");
                throw HBCIError.syntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.syntaxFileError;
        }
    }
    
    func buildMsgs() throws {
        if let root = document.rootElement() {
            if let msgs = root.elements(forName: "MSGs").first {
                for msg in msgs.elements(forName: "MSGdef") {
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
                throw HBCIError.syntaxFileError;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            throw HBCIError.syntaxFileError;
        }
    }
    
    func parseSegment(_ segData:Data, binaries:Array<Data>) throws ->HBCISegment? {
        if let headerDescr = self.degs["SegHead"] {
            if let headerData = headerDescr.parse((segData as NSData).bytes.bindMemory(to: CChar.self, capacity: segData.count), length: segData.count, binaries: binaries) {
                if let code = headerData.elementValueForPath("code") as? String {
                    if let version = headerData.elementValueForPath("version") as? Int {
                        if let segVersion = self.codes[code] {
                            if let segDescr = segVersion.segmentWithVersion(version) {
                                if let seg = segDescr.parse(segData, binaries: binaries) {
                                    return seg;
                                } else {
                                    throw HBCIError.parseError;
                                }
                            }
                        }
                        return nil;  // code and/or version are not supported, just continue
                    }
                }
            }
            logError("Parse error: segment code or segment version could not be determined");
            throw HBCIError.parseError;
        } else {
            logError("Syntax file error: segment SegHead is missing");
            throw HBCIError.syntaxFileError;
        }
    }
    
    func customMessageForSegment(_ segName:String, user:HBCIUser) ->HBCIMessage? {
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
                        logDebug("Process \(segName) is not supported");
                        logDebug(user.parameters.bpSegments.description);
                        return nil;
                    }
                    // now sort the versions - we take the latest supported version
                    supportedVersions.sort(by: >);
                    
                    if let sd = segVersions.segmentWithVersion(supportedVersions.first!) {
                        if let segment = sd.compose() {
                            segment.name = segName;
                            msg.children.insert(segment, at: 2);
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
    
    func addExtension(_ extSyntax:HBCISyntax) {
        for key in extSyntax.degs.keys {
            if !degs.keys.contains(key) {
                degs[key] = extSyntax.degs[key];
            }
        }
        for key in extSyntax.segs.keys {
            if !segs.keys.contains(key) {
                if let segv = extSyntax.segs[key] {
                    segs[key] = segv;
                    codes[segv.code] = segv;
                }
            }
        }
    }
    
    class func syntaxWithVersion(_ version:String) throws ->HBCISyntax {
        if !["220", "300"].contains(version) {
            throw HBCIError.invalidHBCIVersion(version);
        }
        
        if let syntax = syntaxVersions[version] {
            return syntax;
        } else {
            // load syntax
            var path = Bundle.main.bundlePath;
            path = path + "/Contents/Frameworks/HBCI4Swift.framework/Resources/hbci\(version).xml";
            let syntax = try HBCISyntax(path: path);
            
            if let extSyntax = HBCISyntaxExtension.instance.extensions[version] {
                syntax.addExtension(extSyntax);
            }
            
            syntaxVersions[version] = syntax;
            return syntax;
        }
    }
}

