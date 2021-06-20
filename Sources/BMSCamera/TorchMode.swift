//
//  TorchMode.swift
//  BMSCard
//
//  Created by Mikhail Baranov on 14.12.2020.
//  Copyright © 2020 ASD Group. All rights reserved.
//

import UIKit
import AVFoundation

/// Wrapper around `AVCaptureTorchMode`
enum TorchMode {
    case on
    case off

    var next: TorchMode {
        switch self {
        case .on:
            return .off
        case .off:
            return .on
        }
    }
    
    var captureTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .on:
            return .on
        case .off:
            return .off
        }
    }
    
}

