//
//  HBCISegmentVersions.swift
//  HBCIBackend
//
//  Created by Frank Emminghaus on 27.12.14.
//  Copyright (c) 2014 Frank Emminghaus. All rights reserved.
//

import Foundation

class HBCISegmentVersions {
    let identifier:String!
    var code: String!                   // todo: replace with let after Xcode bug fixed
    var syntaxElement: NSXMLElement;
    var versions = Dictionary<Int, HBCISegmentDescription>();
    var versionNumbers = Array<Int>();
    
    
    init?(syntax: HBCISyntax, element: NSXMLElement) {
        self.syntaxElement = element;
        self.identifier = element.valueForAttribute("id");
        if self.identifier == nil {
            // error
            logError("Syntax file error: attribute ID is missing for element \(element)");
            return nil;
        }
        self.code = element.valueForAttribute("code");
        if self.code == nil {
            // error
            logError("Syntax file error: attribute CODE is missing for element \(element)");
            return nil;
        }
        
        let all_vers = element.elementsForName("SEGVersion") ;
        for segv in all_vers {
            if let versionString = segv.valueForAttribute("id") {
                if let version = Int(versionString) {
                    // HBCISegmentDescription
                    if let segment = HBCISegmentDescription(syntax: syntax, element: segv, code: code, version: version) {
                        segment.type = identifier;
                        segment.syntaxElement = segv;
                        segment.values["SegHead.version"] = version;
                        segment.values["SegHead.code"] = code;
                        
                        versions[version] = segment;
                        
                        // next version
                        continue;
                    }
                } else {
                    logError("Syntax file error: ID \(versionString) cannot be converted to a number");
                    return nil;
                }
            } else {
                logError("Syntax file error: attribute ID is missing for element \(segv)");
                return nil;
            }
            // error occured
            return nil;
        }

        // get and sort version codes
        self.versionNumbers = Array(versions.keys);
        if self.versionNumbers.count > 0 {
            self.versionNumbers.sortInPlace({$0 < $1})
        } else {
            // error
            logError("Syntax file error: segment \(element) has no versions");
            return nil;
        }

        // values
        let all_values = element.elementsForName("value") ;
        for elem in all_values {
            if let path = elem.valueForAttribute("path") {
                if let value = elem.stringValue {
                    // now set value for all versions
                    for segv in versions.values {
                        segv.values[path] = value;
                    }
                    // next value
                    continue;
                }
            }
            // error occured
            logError("Syntax file error: value element \(elem) could not be parsed");
            return nil;
        }
    }
    
    func latestVersion() ->HBCISegmentDescription {
        return self.versions[self.versionNumbers.last!]!;
    }
    
    func isVersionSupported(version:Int) ->Bool {
        return versionNumbers.indexOf(version) != nil;
    }
    
    func segmentWithVersion(version:Int) -> HBCISegmentDescription? {
        return versions[version];
    }
        
}
