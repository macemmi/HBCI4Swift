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
    var syntaxElement: XMLElement;
    var versions = Dictionary<Int, HBCISegmentDescription>();
    var versionNumbers = Array<Int>();
    
    
    init(syntax: HBCISyntax, element: XMLElement) throws {
        self.syntaxElement = element;
        self.identifier = element.valueForAttribute("id");
        if self.identifier == nil {
            // error
            logInfo("Syntax file error: attribute ID is missing for element \(element)");
            throw HBCIError.syntaxFileError;
        }
        self.code = element.valueForAttribute("code");
        if self.code == nil {
            // error
            logInfo("Syntax file error: attribute CODE is missing for element \(element)");
            throw HBCIError.syntaxFileError;
        }
        
        let all_vers = element.elements(forName: "SEGVersion") ;
        for segv in all_vers {
            if let versionString = segv.valueForAttribute("id") {
                if let version = Int(versionString) {
                    // HBCISegmentDescription
                    let segment = try HBCISegmentDescription(syntax: syntax, element: segv, code: code, version: version);
                    segment.type = identifier;
                    segment.syntaxElement = segv;
                    segment.values["SegHead.version"] = version;
                    segment.values["SegHead.code"] = code;
                    
                    versions[version] = segment;
                    
                    // next version
                    continue;
                } else {
                    logInfo("Syntax file error: ID \(versionString) cannot be converted to a number");
                    throw HBCIError.syntaxFileError;
                }
            } else {
                logInfo("Syntax file error: attribute ID is missing for element \(segv)");
                throw HBCIError.syntaxFileError;
            }
        }

        // get and sort version codes
        self.versionNumbers = Array(versions.keys);
        if self.versionNumbers.count > 0 {
            self.versionNumbers.sort(by: {$0 < $1})
        } else {
            // error
            logInfo("Syntax file error: segment \(element) has no versions");
            throw HBCIError.syntaxFileError;
        }

        // values
        let all_values = element.elements(forName: "value") ;
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
            logInfo("Syntax file error: value element \(elem) could not be parsed");
            throw HBCIError.syntaxFileError;
        }
    }
    
    func latestVersion() ->HBCISegmentDescription {
        return self.versions[self.versionNumbers.last!]!;
    }
    
    func isVersionSupported(_ version:Int) ->Bool {
        return versionNumbers.index(of: version) != nil;
    }
    
    func segmentWithVersion(_ version:Int) -> HBCISegmentDescription? {
        return versions[version];
    }
        
}
