//
//  base64.swift
//  Pokemap
//
//  Created by Justin Oroz on 7/25/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

extension String {

    func base64Encoded() -> String? {
        let plainData = data(using: String.Encoding.utf8)
        //let base64String = plainData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.fromRaw(0)!)
        let base64String = plainData?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))

        return base64String!
    }

    func base64Decoded() -> String? {
        //let decodedData = NSData(base64EncodedString: self, options:NSDataBase64DecodingOptions.fromRaw(0)!)
        let decodedData = Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0))
        let decodedString = String(data: decodedData!, encoding: String.Encoding.utf8)
        return decodedString
    }
}
