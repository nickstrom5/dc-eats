import Foundation

/// The app's web pages and support address, in one place.
/// The site is GitHub Pages at the project address until dc.eatsranked.com resolves (Nick adds a Cloudflare CNAME
/// dc -> nickstrom5.github.io, DNS only; then scripts/make-site.py sets CUSTOM_DOMAIN). GitHub forwards these github.io
/// links to the custom domain after the switch, so a shipped build keeps working; point them at the new domain in the next update.
enum Links {
    static let site = URL(string: "https://nickstrom5.github.io/dc-eats/")!
    /// The app's data updates: scripts/publish_app_data.py writes docs/data/app/ (OTA-DATA.md).
    static let appData = URL(string: site.absoluteString + "data/app/")!
    static let privacy = URL(string: site.absoluteString + "privacy.html")!
    static let terms = URL(string: site.absoluteString + "terms.html")!
    /// DLCP's Basic Business Licenses on Open Data DC (CC BY 4.0)
    static let dlcpLicenses = URL(string: "https://opendata.dc.gov/datasets/85bf98d3915f412c8a4de706f2d13513")!
    /// ABCA's current roster of alcohol license holders (monthly)
    static let abcaRoster = URL(string: "https://abca.dc.gov/page/current-alcohol-license-holders")!
    /// Open Data DC's ward and neighborhood cluster layers (CC BY 4.0)
    static let wards = URL(string: "https://opendata.dc.gov/datasets/c5cd8b40fb784548a6680aead5f919ed")!
    static let clusters = URL(string: "https://opendata.dc.gov/datasets/f6c703ebe2534fc3800609a07bad8f5b")!
    /// DC Health's inspection search; opened, never scraped
    static let inspections = URL(string: "https://dc.healthinspections.us/?a=Inspections")!
    /// DC Health's page on how it inspects (pass/fail, no grades)
    static let inspectionsExplained = URL(string: "https://dchealth.dc.gov/service/understanding-food-establishment-inspections")!
    static let supportEmail = "nick@eatsranked.com"

    static var correctionEmail: URL {
        URL(string: "mailto:\(supportEmail)?subject=DC%20Eats%20correction")!
    }

    // MARK: Share

    /// The web app. It opens a place's panel from the hash, explore/#p=<id> (readHash in scripts/explore.js), using the app's ids.
    static let explore = URL(string: site.absoluteString + "explore/")!

    /// What Share sends: the place's own page in the web app, never an Apple Maps or Google link (Apple Maps has its own button).
    /// The id is escaped the way the page's encodeURIComponent would escape it. The web app lists every place
    /// the app does (a unit test checks the ids against docs/data).
    /// The web app lists restaurants only: the venues the app hides by default (stadium stands, gas-station counters) aren't there.
    static func onWeb(_ place: Place) -> Bool { !place.isVenue }
    static func share(_ place: Place) -> URL {
        guard onWeb(place), let id = place.id.addingPercentEncoding(withAllowedCharacters: uriComponent),
              let url = URL(string: explore.absoluteString + "#p=" + id) else { return explore }
        return url
    }

    /// The text that goes with the link: the place, its town and the app. No street address, which Messages turns into a Maps link.
    static func shareMessage(_ place: Place) -> String {
        [place.name, place.city ?? ""].filter { !$0.isEmpty }.joined(separator: ", ") + ", on DC Eats"
    }

    /// What encodeURIComponent leaves as is.
    private static let uriComponent = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
}
