//
//  HBCIVoPRequestOrder.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 06.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//
import Foundation

open class HBCIVoPRequestOrder : HBCIOrder {
    
    var vop_id :        Data?
    var polling_id :    Data?
    var waitTime :      NSNumber?
    var offset :        String?
    var descriptor :    String?
    var result :        HBCIVoPResult?
    
    public init?(message: HBCICustomMessage) {
        super.init(name: "VerificationOfPayee", message: message);

        if self.segment == nil {
            return nil;
        }
    }
    
    override func checkTANParameters() -> Bool {
        return true;
    }
    
    open func enqueue() -> Bool {
        
        // check if pain message version is supported
        guard let params = user.parameters.getVoPParameters() else { return false }
        if !params.supportedFormats.contains(where: {$0.contains("pain.002.001.10") }) {
            logDebug("bank does not support pain_002_001_10");
            return false;
        }
        
        if(!self.segment.setElementValue("urn:iso:std:iso:20022:tech:xsd:pain.002.001.10", path: "supported_reports.sepa_descriptor")) {
            logInfo("VoP Order values could not be set");
            return false;
        }
        if let pollId = polling_id {
            if(!self.segment.setElementValue(pollId, path: "pollingId")) {
                logInfo("VoP Order polling id could not be set");
                return false;
            }
        }
        if let offset = self.offset {
            if(!self.segment.setElementValue(offset, path: "offset")) {
                logInfo("VoP Order offset could not be set");
                return false;
            }
        }
        
        return msg.addVoPRequestOrder(self);
    }
    
    override open func updateResult(_ result: HBCIResultMessage) {
        super.updateResult(result);
        
        // check if the result is incomplete
        self.offset = nil;
        for response in result.segmentResponses {
            if response.code == "3040" && response.parameters.count > 0 {
                self.offset = response.parameters[0];
            }
        }
        
        if let retSeg = resultSegments.first {
            if let de = retSeg.elementForPath("vopid") as? HBCIDataElement {
                self.vop_id = de.value as? Data;
                
                if let de = retSeg.elementForPath("descriptor") as? HBCIDataElement {
                    self.descriptor = de.value as? String;
                }
                if let de = retSeg.elementForPath("report") as? HBCIDataElement {
                    if let document = de.value as? Data {
                        let parser = HBCISepaPaymentStatusParser_002_001_10();
                        self.result = parser.parse(document);
                    }
                } else {
                    logInfo("we have no VOP sepa report. Continue with segment information");
                    self.result = HBCIVoPResult(segment: retSeg);
                }
            }
            
            if let de = retSeg.elementForPath("pollingId") as? HBCIDataElement {
                self.polling_id = de.value as? Data;
                if let pollingId = self.polling_id {
                    if(!self.segment.setElementValue(pollingId, path: "pollingId")) {
                        logInfo("VoP Order polling id could not be set");
                    }
                }
            }
            
            if let de = retSeg.elementForPath("waitTime") as? HBCIDataElement {
                self.waitTime = de.value as? NSNumber;
            }
        }
        
        if let offset = self.offset, let pollingId = self.polling_id {
            guard let vopMsg = HBCICustomMessage.newInstance(msg.dialog) else {
                logDebug("process VoP polling: customer message could not be created");
                return;
            }
            
            guard let vopRequest = HBCIVoPRequestOrder(message: vopMsg) else {
                logDebug("process VoP polling: VoP Order could not be created");
                return;
            }
            
            vopRequest.polling_id = pollingId;
            vopRequest.offset = offset;
            
            if !vopRequest.enqueue() {
                logDebug("process VoP polling: VoP Order could not be enqueued");
                return;
            }
            
            logDebug(vopMsg.description);
            
            
            var wait = self.waitTime?.intValue ?? 2;
            if wait < 2 {
                wait = 2;
            }

            do {
                usleep(UInt32(wait*1000000));
                
                if(try vopMsg.sendNoTan() == false) {
                    logDebug("process VoP polling: VoP message could not be sent");
                    return;
                }
            
                if let vop_id = vopRequest.vop_id {
                    self.vop_id = vop_id;
                    self.descriptor = vopRequest.descriptor;
                    self.result = vopRequest.result;
                    return;
                }
            }
            catch {
                return;
            }
        }
    }
        
}
