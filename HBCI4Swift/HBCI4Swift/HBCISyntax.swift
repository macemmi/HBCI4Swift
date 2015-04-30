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
    
    init?(path: String, error: NSErrorPointer) {
        var xmlDoc: NSXMLDocument?
        let furl = NSURL.fileURLWithPath(path)
        if furl != nil {
            xmlDoc = NSXMLDocument(contentsOfURL: furl!, options:Int(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA), error: error)
        } else {
            error.memory = createError(HBCIErrorCodes.URLError.rawValue, "URL for path \(path) could not be created", nil);
        }
        
        if xmlDoc == nil {
            xmlDoc = NSXMLDocument(contentsOfURL: furl!, options: Int(NSXMLDocumentTidyXML), error: error)
        }
        if xmlDoc == nil {
            return nil;
        } else {
            document = xmlDoc!;
        }
        
        if(!buildDegs()) {
            error.memory = createError(HBCIErrorCodes.SyntaxFileError.rawValue, "Error in HBCI syntax file. See log for more information", nil);
            return nil;
        }
        if(!buildSegs()) {
            error.memory = createError(HBCIErrorCodes.SyntaxFileError.rawValue, "Error in HBCI syntax file. See log for more information", nil);
            return nil;
        }
        if(!buildMsgs()) {
            error.memory = createError(HBCIErrorCodes.SyntaxFileError.rawValue, "Error in HBCI syntax file. See log for more information", nil);
            return nil;
        }
    }
    
    func buildDegs() ->Bool {
        if let root = document.rootElement() {
            if let degs = root.elementsForName("DEGs").first as? NSXMLElement {
                if let all_degs = degs.elementsForName("DEGdef") as? [NSXMLElement] {
                    for deg in all_degs {
                        if let identifier = deg.valueForAttribute("id"), elem = HBCIDataElementGroupDescription(syntax: self, element: deg) {
                            elem.syntaxElement = deg
                            self.degs[identifier] = elem
                        } else {
                            // syntax error
                            logError("Syntax file error: invalid DEGdef element found");
                            return false;
                        }
                    }
                    return true;
                } else {
                    // error
                    logError("Syntax file error: DEGdefs not found");
                    return false;
                }
            } else {
                // error
                logError("Syntax file error: DEGs element not found");
                return false;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            return false;
        }
    }
    
    func buildSegs() ->Bool {
        if let root = document.rootElement() {
            if let segs = root.elementsForName("SEGs").first as? NSXMLElement {
                if let all_segs = segs.elementsForName("SEGdef") as? [NSXMLElement] {
                    for seg in all_segs {
                        if let segv = HBCISegmentVersions(syntax: self, element: seg) {
                            self.segs[segv.identifier] = segv;
                            self.codes[segv.code] = segv;
                        } else {
                            // syntax error
                            logError("Syntax file error: invalid SEGdef element found");
                            return false;
                        }
                    }
                    return true;
                } else {
                    // error
                    logError("Syntax file error: SEGdefs not found");
                    return false;
                }
            } else {
                // error
                logError("Syntax file error: SEGs element not found");
                return false;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            return false;
        }
    }
    
    func buildMsgs() ->Bool {
        if let root = document.rootElement() {
            if let msgs = root.elementsForName("MSGs").first as? NSXMLElement {
                if let all_msgs = msgs.elementsForName("MSGdef") as? [NSXMLElement] {
                    for msg in all_msgs {
                        if let identifier = msg.valueForAttribute("id"), elem = HBCIMessageDescription(syntax: self, element: msg) {
                            elem.syntaxElement = msg;
                            self.msgs[identifier] = elem;
                        } else {
                            // syntax error
                            logError("Syntax file error: invalid MSGdef element found");
                            return false;
                        }
                    }
                    return true;
                } else {
                    // error
                    logError("Syntax file error: MSGdefs not found");
                    return false;
                }
            } else {
                // error
                logError("Syntax file error: MSGs element not found");
                return false;
            }
        } else {
            // error
            logError("Synax file error: root element not found");
            return false;
        }
    }
    
    func parseSegment(segData:NSData, binaries:Array<NSData>) ->(segment:HBCISegment?, parseError:Bool) {
        if let headerDescr = self.degs["SegHead"] {
            if let headerData = headerDescr.parse(UnsafePointer<CChar>(segData.bytes), length: segData.length, binaries: binaries) {
                if let code = headerData.elementValueForPath("code") as? String {
                    if let version = headerData.elementValueForPath("version") as? Int {
                        if let segVersion = self.codes[code] {
                            if let segDescr = segVersion.segmentWithVersion(version) {
                                if let seg = segDescr.parse(segData, binaries: binaries) {
                                    return (seg, false);
                                } else {
                                    return (nil, true);
                                }
                            }
                        }
                        return (nil, false);  // code and/or version are not supported, just continue
                    }
                }
            }
            logError("Parse error: segment code or segment version could not be determined");
            return (nil, true);
        } else {
            logError("Syntax file error: segment SegHead is missing");
            return (nil, true);
        }
    }
    
    func customMessageForSegment(segName:String, user:HBCIUser) ->HBCIMessage? {
        if let md = self.msgs["CustomMsg"] {
            if var msg = md.compose() as? HBCIMessage {
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
                    sort(&supportedVersions, >);
                    
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
    
    class func syntaxWithVersion(version:String, error:NSErrorPointer) ->HBCISyntax? {
        if let syntax = syntaxVersions[version] {
            return syntax;
        } else {
            // load syntax
            var path = NSBundle.mainBundle().bundlePath;
            path = path + "/Contents/Frameworks/HBCIFramework.framework/Resources/hbci\(version).xml";
            if let syntax = HBCISyntax(path: path, error: error) {
                syntaxVersions[version] = syntax;
                return syntax;
            } else {
                logError("HBCI syntax file not found: " + path);
                return nil;
            }
        }
    }
}

