import Foundation
import LocalAuthentication

enum BiometricKind {
    case none, touchID, faceID, opticID

    var label: String {
        switch self {
        case .none:    return "Biometrics"
        case .touchID: return "Touch ID"
        case .faceID:  return "Face ID"
        case .opticID: return "Optic ID"
        }
    }

    var systemImage: String {
        switch self {
        case .none:    return "lock"
        case .touchID: return "touchid"
        case .faceID:  return "faceid"
        case .opticID: return "opticid"
        }
    }
}

enum BiometricAuth {
    static var available: Bool {
        let ctx = LAContext()
        var error: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static var kind: BiometricKind {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch ctx.biometryType {
        case .touchID: return .touchID
        case .faceID:  return .faceID
        #if swift(>=5.9)
        case .opticID: return .opticID
        #endif
        default:       return .none
        }
    }
}
