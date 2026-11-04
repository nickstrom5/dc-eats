import CoreLocation
import Observation
import UIKit

/// "Near me" sorting. Asks for when-in-use permission only when a list is sorted by distance or "My location" is tapped; the location never leaves the device.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var location: CLLocation?
    private(set) var status: CLAuthorizationStatus = .notDetermined
    /// no fix within 12 seconds, or Core Location reported an error
    private(set) var failed = false
    private var timeout: Task<Void, Never>?
    /// when the current request started: a fix from before it is a cached one (from launch, or before a drive) and doesn't count
    private var askedAt = Date.distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        status = manager.authorizationStatus
    }

    var isDenied: Bool { status == .denied || status == .restricted }

    /// Every place is in the District, so a reader elsewhere (an App Reviewer in California, or someone across the river in Arlington)
    /// gets told rather than an empty map. A coarse outline of the District (a bounding box would count Arlington, Silver Spring and
    /// Bethesda), drawn about 150 m outside the line so places on the boundary streets count as inside.
    var isOutsideDC: Bool {
        guard let c = location?.coordinate else { return false }
        return !DCOutline.contains(c)
    }

    /// Once location is off for the app, iOS won't ask again; the app's page in Settings is the only way back.
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: locate()
        default: break
        }
    }

    private func locate() {
        failed = false
        let asked = Date()
        askedAt = asked
        manager.requestLocation()
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(12))
            guard let self, !Task.isCancelled else { return }
            if (self.location?.timestamp ?? .distantPast) < asked { self.failed = true }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        let s = m.authorizationStatus
        Task { @MainActor in
            self.status = s
            if s == .authorizedWhenInUse || s == .authorizedAlways { self.locate() }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let l = locations.last else { return }
        Task { @MainActor in
            // "My location" needs a fresh fix on every tap: a cached one from before the request would put you back where you were
            guard l.timestamp >= self.askedAt.addingTimeInterval(-2) else { return }
            self.location = l; self.failed = false; self.timeout?.cancel()
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in if self.location == nil { self.failed = true } }
    }
}

extension CLLocation {
    /// "0.4 mi", "12 mi", "1,012 mi" (an App Reviewer in California is a thousand miles out)
    func milesText(to other: CLLocation) -> String {
        let mi = distance(from: other) / 1609.344
        return (mi < 10 ? mi.formatted(.number.precision(.fractionLength(1))) : Int(mi.rounded()).formatted()) + " mi"
    }
}

/// A coarse District of Columbia outline (longitude, latitude), 35 points, nudged about 150 m outward (from Open Data DC's boundary:
/// buffer 0.0015°, simplify 0.0012°; every bundled place falls inside it, and DCA, Rosslyn, Silver Spring and Bethesda fall outside).
enum DCOutline {
    static let ring: [(Double, Double)] = [
        (-77.1212, 38.9338), (-77.0407, 38.9974), (-76.9077, 38.8926), (-77.0393, 38.7902), (-77.0407, 38.8007), (-77.0378, 38.8139),
        (-77.0426, 38.8234), (-77.0402, 38.8254), (-77.0393, 38.8298), (-77.0444, 38.8304), (-77.0494, 38.8412), (-77.0470, 38.8428),
        (-77.0365, 38.8411), (-77.0344, 38.8454), (-77.0338, 38.8521), (-77.0364, 38.8587), (-77.0442, 38.8630), (-77.0432, 38.8651),
        (-77.0393, 38.8654), (-77.0407, 38.8688), (-77.0449, 38.8732), (-77.0462, 38.8705), (-77.0492, 38.8698), (-77.0500, 38.8699),
        (-77.0505, 38.8701), (-77.0509, 38.8703), (-77.0510, 38.8704), (-77.0553, 38.8787), (-77.0601, 38.8797), (-77.0655, 38.8878),
        (-77.0695, 38.8991), (-77.0886, 38.9019), (-77.1040, 38.9116), (-77.1076, 38.9183), (-77.1171, 38.9272)]

    /// Ray casting: a point is inside when a ray east of it crosses the outline an odd number of times.
    static func contains(_ c: CLLocationCoordinate2D) -> Bool {
        var inside = false
        var j = ring.count - 1
        for i in 0..<ring.count {
            let (xi, yi) = ring[i], (xj, yj) = ring[j]
            if (yi > c.latitude) != (yj > c.latitude) && c.longitude < (xj - xi) * (c.latitude - yi) / (yj - yi) + xi { inside.toggle() }
            j = i
        }
        return inside
    }
}
