//
//  File.swift
//  HBCI4Swift
//
//  Created by Frank Emminghaus on 08.09.25.
//  Copyright © 2025 Frank Emminghaus. All rights reserved.
//


    public init?(message: HBCICustomMessage) {
        super.init(name: "VerificationOfPayee", message: message);

        if self.segment == nil {
            return nil;
        }
    }
