import SwiftUI

struct AboutView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DC EATS").displayFont(32).foregroundStyle(Theme.green)
                    Text("A free guide to \(model.restaurantCount.formatted()) restaurants in the District of Columbia, with MICHELIN and James Beard honors, the District's own business and alcohol licenses, and hand-checked lists of DC's own food. No account, no ads, no tracking.")
                        .font(.subheadline).foregroundStyle(Theme.ink2)
                    Text("DC Eats is an independent app by Nicholas Soderstrom. It is not affiliated with, endorsed by or operated by the Government of the District of Columbia, DC Health, the Department of Licensing and Consumer Protection, the Alcoholic Beverage and Cannabis Administration, Open Data DC, Destination DC, the MICHELIN Guide, the James Beard Foundation, Apple, any sports team, or any restaurant or chain. Other names are trademarks of their owners.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                }
                .padding(.vertical, 4)
            }
            Section("How the lists are built") {
                Text("Hand-checked lists (half-smokes and chili, mumbo sauce carryouts, jumbo slice, Ethiopian, pupuserías, the fish market and the Wharf) include only places named for that food by a source and shown to be operating in 2025 or 2026: the MICHELIN Guide, the place's own website, dated local press, or a current DC business or alcohol license. Addresses are checked against the District's own address list. Founding years mean the year it opened at this address.")
                Text("Honors are the MICHELIN Guide Washington, D.C. (two-star and one-star restaurants, Bib Gourmands and recommended places, and its Green Star), James Beard Foundation winners, the 2026 nominees and semifinalists, and America's Classics.")
                Text("This app starts from open map listings (Overture Maps) and keeps the kinds that proved reliable: checked against the District's own licenses, which every restaurant, carryout and bakery needs, high-confidence listings matched a license far more often than the kinds left out. The licenses also confirm places and add restaurants and bars the map data missed. A place whose food and alcohol licenses both lapsed long ago is left out as closed. Adult clubs are left out. Website links are checked, and any that no longer belong to the place are left out.")
                Text("Neighborhoods come from the District's own neighborhood clusters and label points, with its historic districts deciding the name for a place inside one (Shaw, Dupont Circle, Georgetown), and wards from its 2022 ward map. The District draws no official neighborhood lines, so a place near a border can carry the next neighborhood's name.")
                Text("DC Health inspects food establishments pass/fail and gives no grade, score or placard. Its reports are posted only in its own search, linked from each place; nothing is copied and no grade is computed. DC Health's own note: \u{201C}Keep in mind that any inspection report is a \u{2018}snapshot\u{2019} of the day and time of the inspection. On any given day, a food establishment could have fewer or more violations than noted in the report. An inspection conducted on any given day may not be representative of the overall, long-term cleanliness of an establishment. Also, at the time of the inspection violations are recorded but are often corrected on-the-spot prior to the inspector leaving the establishment.\u{201D}")
                Text("Ratings, reviews, hours and photos are Apple Maps' own, shown live in Apple's place card. This app doesn't store or rank by them.")
            }
            .font(.subheadline).foregroundStyle(Theme.ink2)
            Section("Sources") {
                source("Department of Licensing and Consumer Protection", "Basic Business Licenses, Open Data DC (opendata.dc.gov), refreshed \(DayFormat.text(model.permitsUpdated) ?? model.permitsUpdated). Licensed under CC BY 4.0 (creativecommons.org/licenses/by/4.0); filtered to food licenses and matched to map listings for this app. License holders' and owners' names are left out.", Links.dlcpLicenses.absoluteString)
                source("Alcoholic Beverage and Cannabis Administration", "Alcohol License Holders\(model.abcRoster.flatMap { DayFormat.monthYear($0 + "-01") }.map { ", \($0)" } ?? "") (abca.dc.gov), with ABCA's Alcohol License Business Locations and Alcohol License Cancellations on Open Data DC (CC BY 4.0). License numbers, classes, endorsements and expiry dates as published; licensee names left out.", Links.abcaRoster.absoluteString)
                source("Open Data DC", "The District's boundary, Wards from 2022, Neighborhood Clusters, Neighborhood Labels, Historic Districts and Address Points (the Master Address Repository). Licensed under CC BY 4.0.", Links.clusters.absoluteString)
                source("DC Health", "Food establishment inspections, pass/fail, in DC Health's own search (dc.healthinspections.us). Linked from each place; not copied.", Links.inspectionsExplained.absoluteString)
                source("Overture Maps Foundation", "Restaurant listings and websites come from Overture Maps Foundation places data (overturemaps.org)\(model.overtureRelease.map { ", release \($0)" } ?? ""), filtered and reformatted for this app.\n• Data from Meta, Microsoft, DAC and BrightQuery. Available under CDLA Permissive 2.0.\n• Data from Foursquare. \(foursquareCopyright) Available under Apache 2.0. Foursquare data was transformed to the Overture schema; this app further filtered and reformatted it. See the NOTICE below.\n• Data from AllThePlaces. Available under CC0 1.0.", "https://overturemaps.org")
                source("Honors", "The MICHELIN Guide Washington, D.C. selection and James Beard Foundation awards, nominees, semifinalists and America's Classics are reported as facts and checked by hand against the official pages. MICHELIN and the MICHELIN Guide are trademarks of Michelin. James Beard Foundation and James Beard Award are trademarks of the James Beard Foundation. Other names belong to their owners.", "https://guide.michelin.com/us/en/district-of-columbia/restaurants")
                source("Maps", "Maps, place cards and directions by Apple Maps.", nil)
            }
            Section("Licenses") {
                NavigationLink("Community Data License Agreement – Permissive 2.0") { LicenseText(file: "CDLA-Permissive-2.0", title: "CDLA Permissive 2.0") }
                NavigationLink("Apache License 2.0") { LicenseText(file: "Apache-2.0", title: "Apache License 2.0") }
                NavigationLink("Foursquare OS Places NOTICE") { LicenseText(file: "Foursquare-NOTICE", title: "Foursquare NOTICE") }
            }
            Section("Privacy") {
                Text("The app collects nothing. Your location, if you allow it, only sorts lists by distance and shows where you are on the map, on this device. Saved places stay on this device.")
                    .font(.subheadline).foregroundStyle(Theme.ink2)
                DataUpdatesNote()
                    .font(.footnote).foregroundStyle(Theme.muted)
                Link("Privacy policy", destination: Links.privacy)
                Link("Terms of use", destination: Links.terms)
            }
            Section("Help") {
                Link("Report a missing or closed place", destination: Links.correctionEmail)
                Link("Email \(Links.supportEmail)", destination: URL(string: "mailto:\(Links.supportEmail)")!)
                Link("Website", destination: Links.site)
                Text("Data as of \(DayFormat.text(model.generated) ?? model.generated). Places open and close; check before you go. Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.footnote).foregroundStyle(Theme.muted)
            }
        }
        .navigationTitle("About")
        .tint(Theme.green)
    }

    /// the copyright line exactly as the bundled Foursquare NOTICE has it, so the two can't disagree
    private var foursquareCopyright: String {
        guard let url = Bundle.main.url(forResource: "Foursquare-NOTICE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8),
              let line = text.split(separator: "\n").first(where: { $0.hasPrefix("©") }) else { return "© Foursquare Labs, Inc. All rights reserved." }
        return line.trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private func source(_ name: String, _ detail: String, _ url: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let url, let u = URL(string: url) { Link(name, destination: u).font(.subheadline.weight(.semibold)) }
            else { Text(name).font(.subheadline.weight(.semibold)) }
            Text(detail).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// A bundled license text (Resources/Licenses), reflowed rather than shown as raw 80-column lines.
struct LicenseText: View {
    let file: String
    let title: String

    var body: some View {
        ScrollView {
            Text(text).font(.footnote).foregroundStyle(Theme.ink).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .inlineTitle(title)
    }

    private var text: String {
        guard let url = Bundle.main.url(forResource: file, withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return "License text missing." }
        // join hard-wrapped lines into paragraphs; keep blank lines and list items as breaks
        var out: [String] = []
        for para in raw.components(separatedBy: "\n\n") {
            let lines = para.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            var joined = ""
            for l in lines where !l.isEmpty {
                let startsItem = l.hasPrefix("–") || l.hasPrefix("-") || l.range(of: #"^\(?[a-z0-9]{1,3}[.)]\s"#, options: .regularExpression) != nil
                joined += joined.isEmpty ? l : (startsItem ? "\n" + l : " " + l)
            }
            if !joined.isEmpty { out.append(joined) }
        }
        return out.joined(separator: "\n\n")
    }
}
