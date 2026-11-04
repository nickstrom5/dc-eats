import Foundation
import CoreLocation
import UIKit

/// `-screenshot <name>` opens one screen with fixed state for App Store screenshots (scripts/capture-screenshots.sh).
/// Names: home, honors, oldest, patios, half_smokes, ethiopian, detail, map, saved, about.
enum ScreenshotMode {
    /// Debug builds only: an App Store build ignores the launch argument, so no one can reach seeded screens or fake locations.
    static var name: String? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
        #else
        return nil
        #endif
    }
    static var isActive: Bool { name != nil }

    @MainActor
    static func apply(to model: AppModel) {
        guard let name, model.isLoaded else { return }
        model.filters = Filters()
        // Dupont Circle (Connecticut Ave at P St NW), so "nearest" lists have distances without a permission prompt
        model.screenshotLocation = CLLocation(latitude: 38.9097, longitude: -77.0434)
        // by name and neighborhood, ignoring case, so a rebuild with a slightly different casing still finds the place; the
        // hand-checked one first
        let pick = { (n: String, town: String?) -> Place? in
            let hits = model.places.filter { $0.name.caseInsensitiveCompare(n) == .orderedSame && (town == nil || $0.city == town) }
            return hits.first(where: \.handChecked) ?? hits.first
        }
        for p in [pick("Rose's Luxury", nil), pick("Ben's Chili Bowl", "Shaw"), pick("Maketto", nil)]
            .compactMap({ $0 }) where !model.isSaved(p) {
            model.toggleSaved(p)
        }
        let open = { (g: Guide) in model.tab = .guides; model.selectedGuide = g; model.guidesPath = [.guide(g)] }
        switch name {
        case "honors": open(.honors)
        case "oldest": open(.oldest)
        case "patios": open(.patios)
        case "half_smokes": open(.halfSmokes)
        case "ethiopian":
            // from U Street (U St at 14th St NW), near Shaw's Ethiopian row
            model.screenshotLocation = CLLocation(latitude: 38.9170, longitude: -77.0321)
            open(.ethiopian)
        case "detail":
            // Rose's Luxury: one MICHELIN star, with its DLCP and ABCA licenses
            open(.honors)
            if let p = pick("Rose's Luxury", nil) ?? model.places.first {
                model.selectedPlace = p; model.guidesPath.append(.place(p))
            }
        case "map": model.tab = .map
        case "saved": model.tab = .saved
        case "about": model.tab = .about
        default: model.tab = .guides; model.selectedGuide = nil
        }
        // iPad shows the place column next to every list, so give each shot a place instead of "Pick a place": a different
        // honored or hand-checked one per shot.
        guard UIDevice.current.userInterfaceIdiom == .pad, model.selectedPlace == nil else { return }
        let place: Place? = switch name {
        case "home": pick("Ben's Chili Bowl", "Shaw")
        case "map": pick("Oyster Oyster", nil)
        case "honors": pick("Jônt", nil)
        case "oldest": pick("Ben's Chili Bowl", "Shaw")
        case "patios": pick("Maketto", nil)
        case "saved": pick("Maketto", nil)
        case "about": nil
        default: pick("Rose's Luxury", nil)
        }
        model.selectedPlace = place
    }
}
