//
//  VideoPermissionService.swift
//  BMSCard
//
//  Created by Mikhail Baranov on 18.12.2020.
//  Copyright © 2020 ASD Group. All rights reserved.
//

import AVFoundation

/// Service used to check authorization status of the capture device
final class VideoPermissionService {
    enum Error: Swift.Error {
        case notAuthorizedToUseCamera
    }

    // MARK: Authorization
    func checkPersmission(completion: @escaping (Error?) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(nil)
        case .notDetermined:
            askForPermissions(completion)
        default:
            completion(Error.notAuthorizedToUseCamera)
        }
    }

    private func askForPermissions(_ completion: @escaping (Error?) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                guard granted else {
                    completion(Error.notAuthorizedToUseCamera)
                    return
                }
                completion(nil)
            }
        }
    }
}
