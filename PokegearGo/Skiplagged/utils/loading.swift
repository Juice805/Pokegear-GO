//
//  loading.swift
//  Pokegear GO
//
//  Created by Justin Oroz on 8/2/16.
//  Copyright © 2016 Justin Oroz. All rights reserved.
//

import Foundation

enum LoginSteps: Int {
	case Started = 0
	case Connected
	case Ticket
	case Token
	case APIEndpoint1
	case APIEndpoint2
	case APIEndpoint3
	case Profile1
	case Profile2
	case Profile3
	case Complete
}
