import XCTest
import CoreLocation
@testable import DCEats

@MainActor
final class DCEatsTests: XCTestCase {

    /// A tiny core file and its detail file with the same shape as Resources/places.json and Resources/detail-district-of-columbia.json.
    private func sampleModel() async throws -> AppModel {
        let json = """
        {"v":1,"generated":"2026-10-27","overture_release":"2026-10-21.0","permits_updated":"2026-10-27",
         "permits_url":"https://opendata.dc.gov/datasets/85bf98d3915f412c8a4de706f2d13513","abc_roster":"2026-10",
         "abc_url":"https://abca.dc.gov/page/current-alcohol-license-holders","inspections_url":"https://dc.healthinspections.us/?a=Inspections",
         "inspections_through":{},"results":[],
         "cities":["Shaw","Penn Quarter","Adams Morgan","Capitol Hill","Georgetown","Near Northeast"],
         "cuisines":["Hot Dogs & Sausages","American & Other","Pizza","African","Coffee & Café","Latin & Caribbean"],
         "brands":["&pizza"],"counties":["Ward 1","Ward 2","Ward 6"],
         "regions":["District of Columbia"],
         "srcs":["official","meta","AllThePlaces","DAC","research"],
         "count":9,"count_restaurants":8,
         "calibration":{"District of Columbia (DLCP food licenses + ABCA alcohol licenses)":{"listings":5929,"groups":{"meta_high":{"n":1909,"official":0.771}}}},
         "places":[
          {"id":"a","n":"Ben's Chili Bowl","c":0,"co":0,"rg":0,"cu":0,"t":2,"s":1,"hc":1,"g":65,"h":17,"jbf":"America's Classic 2004","f":1958,"ip":60,
           "a":"1213 U St NW","z":"20009","la":38.9170,"lo":-77.0290,"liq":1,"dish":"half-smoke"},
          {"id":"b","n":"minibar by José Andrés","c":1,"co":1,"rg":0,"cu":1,"t":2,"s":1,"hc":1,"mi":4,"ip":62,"a":"855 E St NW","la":38.8964,"lo":-77.0236,"liq":1},
          {"id":"c","n":"&pizza","c":3,"co":2,"rg":0,"cu":2,"t":1,"s":2,"b":0,"ch":12,"la":38.8820,"lo":-76.9950},
          {"id":"d","n":"Dukem","c":0,"co":0,"rg":0,"cu":3,"t":2,"s":1,"hc":1,"g":8,"a":"1114 U St NW","la":38.9168,"lo":-77.0275,"liq":1,"pt":1,"dish":"injera"},
          {"id":"e","n":"Nationals Park Stand","c":3,"co":2,"rg":0,"cu":1,"t":1,"s":1,"v":1,"la":38.8730,"lo":-77.0074},
          {"id":"f","n":"Jumbo Slice Pizza","c":2,"co":0,"rg":0,"cu":2,"t":2,"s":1,"hc":1,"g":4,"a":"2341 18th St NW","la":38.9210,"lo":-77.0425},
          {"id":"g","n":"Maketto","c":5,"co":2,"rg":0,"cu":1,"t":2,"s":1,"hc":1,"mi":2,"ip":36,"a":"1351 H St NE","la":38.9002,"lo":-76.9862,"liq":1,"pt":1},
          {"id":"h","n":"Martin's Tavern","c":4,"co":1,"rg":0,"cu":1,"t":2,"s":1,"hc":1,"g":64,"f":1933,"a":"1264 Wisconsin Ave NW","la":38.9065,"lo":-77.0628,"liq":1},
          {"id":"i","n":"Georgia Ave Coffee","c":0,"co":0,"rg":0,"cu":4,"t":1,"s":1,"a":"100 Georgia Ave NW","la":38.92,"lo":-77.02}
         ]}
        """
        let detail = """
        {"a":{"lic":[["DLCP business license","70104892","Restaurant","Active","1996-07-11","2027-08-31",[]],
                     ["ABCA alcohol license","ABRA-000001","Restaurant (Class C)","Active","","2028-03-31",["Sidewalk café","Entertainment"]]],
              "ph":"(202) 667-0058","w":"benschilibowl.com","liq":"Restaurant (Class C)"},
         "b":{"lic":[["ABCA alcohol license","ABRA-089911","Restaurant (Class C)","Active","","2028-03-31",[]]],"w":"javascript:alert(1)"},
         "f":{"lic":[["DLCP business license","931324000001","Restaurant","Active"]],"w":"https://www.example.com/"}}
        """
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("dc-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("places.json")
        try json.data(using: .utf8)!.write(to: url)
        try detail.data(using: .utf8)!.write(to: dir.appendingPathComponent("detail-district-of-columbia.json"))
        let model = AppModel(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        await model.load(from: url, detailFolder: dir)
        XCTAssertTrue(model.isLoaded, model.loadError ?? "")
        return model
    }

    func testDecodesAndHidesNonRestaurantsByDefault() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.places.count, 9)
        XCTAssertEqual(m.restaurantCount, 8)
        XCTAssertFalse(m.list(.all, sort: .name, search: "", here: nil).contains { $0.name == "Nationals Park Stand" }, "a ballpark stand is hidden by default")
        m.filters.includeNonRestaurants = true
        XCTAssertTrue(m.list(.all, sort: .name, search: "", here: nil).contains { $0.name == "Nationals Park Stand" })
        XCTAssertEqual(m.permitsUpdated, "2026-10-27")
        XCTAssertEqual(m.abcRoster, "2026-10")
        XCTAssertEqual(m.inspectionsURL?.host, "dc.healthinspections.us")
        XCTAssertEqual(m.place(id: "a")?.county, "Ward 1", "the ward is the place's second area")
    }

    func testGuidesListOnlyWhatTheyPromise() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.list(.halfSmokes, sort: .name, search: "", here: nil).map(\.name), ["Ben's Chili Bowl"])
        XCTAssertEqual(m.list(.ethiopian, sort: .name, search: "", here: nil).map(\.name), ["Dukem"])
        XCTAssertEqual(m.list(.jumboSlice, sort: .name, search: "", here: nil).map(\.name), ["Jumbo Slice Pizza"])
        XCTAssertEqual(m.list(.oldest, sort: .oldest, search: "", here: nil).map(\.name), ["Martin's Tavern", "Ben's Chili Bowl"])
        XCTAssertEqual(m.list(.honors, sort: .iconic, search: "", here: nil).map(\.name), ["minibar by José Andrés", "Maketto", "Ben's Chili Bowl"])
        XCTAssertEqual(m.list(.patios, sort: .name, search: "", here: nil).map(\.name), ["Dukem", "Maketto"], "only places whose own ABCA license carries the endorsement")
        XCTAssertEqual(m.list(.pupusas, sort: .name, search: "", here: nil), [], "a guide with nothing hand-checked yet is empty, not padded")
    }

    /// The District's own records: each license with its number, type, status, first issue date and expiry; alcohol from ABCA only.
    func testLicensesAndAlcohol() async throws {
        let m = try await sampleModel()
        let bens = try XCTUnwrap(m.place(id: "a"))
        XCTAssertTrue(bens.servesAlcohol)
        XCTAssertFalse(try XCTUnwrap(m.place(id: "f")).servesAlcohol, "no ABCA license matched is unknown, not \"no\": the flag is simply off")
        let loaded = await m.detail(for: bens)
        let d = try XCTUnwrap(loaded)
        XCTAssertEqual(d.licenses.map(\.id), ["70104892", "ABRA-000001"])
        XCTAssertEqual(d.licenses.first?.type, "Restaurant")
        XCTAssertEqual(d.licenses.first?.firstIssued, "1996-07-11")
        XCTAssertEqual(d.licenses.first?.expires, "2027-08-31")
        XCTAssertFalse(d.licenses.first!.isAlcohol)
        XCTAssertTrue(d.licenses.last!.isAlcohol)
        XCTAssertNil(d.licenses.last?.firstIssued, "an empty field reads as missing")
        XCTAssertEqual(d.licenses.last?.endorsements, ["Sidewalk café", "Entertainment"])
        XCTAssertEqual(d.liq, "Restaurant (Class C)")
        let shortLoaded = await m.detail(for: m.place(id: "f")!)
        let short = try XCTUnwrap(shortLoaded)
        XCTAssertEqual(short.licenses.first?.status, "Active", "a shorter license row still decodes")
        XCTAssertNil(short.licenses.first?.expires)
        XCTAssertEqual(short.licenses.first?.endorsements, [])
    }

    func testDatesAreCalendarDays() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let d = DayFormat.date("2026-06-16")!
        XCTAssertEqual(utc.dateComponents([.year, .month, .day], from: d), DateComponents(year: 2026, month: 6, day: 16))
        XCTAssertTrue(DayFormat.monthYear("2025-09-01")!.contains("2025"))
        XCTAssertNil(DayFormat.date("2026-13-01"))
        XCTAssertEqual(DayFormat.text("soon"), "soon", "a value that isn't a date is shown as it is")
    }

    func testDetailsLoadOnDemand() async throws {
        let m = try await sampleModel()
        let v = await m.detail(for: m.place(id: "a")!)
        XCTAssertEqual(v?.website?.absoluteString, "https://benschilibowl.com", "a bare host gets https://")
        let b = await m.detail(for: m.place(id: "b")!)
        XCTAssertNil(b?.website, "a javascript: link never becomes a website button")
        XCTAssertEqual(AppModel.regionSlug("District of Columbia"), "district-of-columbia")
        let none = await m.detail(for: m.place(id: "i")!)
        XCTAssertNil(none, "a place with no detail reads as no detail, not a crash")
    }

    func testSearchWordStartsNeighborhoodsAndGuides() async throws {
        let m = try await sampleModel()
        XCTAssertEqual(m.list(.all, sort: .name, search: "bens", here: nil).map(\.name), ["Ben's Chili Bowl"], "apostrophes don't matter")
        XCTAssertEqual(m.list(.all, sort: .name, search: "shaw", here: nil).map(\.name), ["Ben's Chili Bowl", "Dukem", "Georgia Ave Coffee"], "a neighborhood narrows to it")
        XCTAssertEqual(m.list(.all, sort: .name, search: "🍕", here: nil), [], "an emoji finds nothing, not everything")
        XCTAssertEqual(m.list(.all, sort: .name, search: "half-smoke", here: nil).map(\.name), ["Ben's Chili Bowl"], "a guide word means the guide")
        XCTAssertEqual(m.list(.all, sort: .name, search: "jumbo slice", here: nil).map(\.name), ["Jumbo Slice Pizza"])
        XCTAssertEqual(m.list(.all, sort: .name, search: "injera", here: nil).map(\.name), ["Dukem"], "a dish finds the places that serve it")
        XCTAssertEqual(m.list(.all, sort: .name, search: "georgia ave", here: nil).map(\.name), ["Georgia Ave Coffee"], "a street, not a neighborhood")
    }

    func testOutsideDCUsesTheOutline() {
        func inside(_ la: Double, _ lo: Double) -> Bool { DCOutline.contains(CLLocationCoordinate2D(latitude: la, longitude: lo)) }
        XCTAssertTrue(inside(38.9170, -77.0290), "U Street"); XCTAssertTrue(inside(38.9055, -77.0632), "Georgetown")
        XCTAssertTrue(inside(38.8790, -77.0230), "the Wharf"); XCTAssertTrue(inside(38.8620, -76.9880), "Anacostia")
        XCTAssertTrue(inside(38.9650, -77.0760), "Chevy Chase DC"); XCTAssertTrue(inside(38.9010, -76.9330), "Deanwood")
        XCTAssertFalse(inside(38.8512, -77.0402), "DCA (Arlington)"); XCTAssertFalse(inside(38.8957, -77.0731), "Rosslyn")
        XCTAssertFalse(inside(38.9906, -77.0262), "Silver Spring"); XCTAssertFalse(inside(38.9809, -77.0927), "Bethesda")
        XCTAssertFalse(inside(38.8048, -77.0469), "Old Town Alexandria"); XCTAssertFalse(inside(37.33, -122.03), "Cupertino")
    }

    func testBundledData() async throws {
        let m = AppModel(defaults: UserDefaults(suiteName: "bundle-\(UUID().uuidString)")!)
        await m.load()
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        XCTAssertGreaterThan(m.restaurantCount, 2_500)
        XCTAssertGreaterThanOrEqual(m.count(.honors), 100)
        XCTAssertEqual(m.bibCount, 28, "the District's 28 Bib Gourmands (MICHELIN Guide Washington, D.C., read 2026-10-27)")
        XCTAssertEqual(Set(m.places.filter { $0.michelin == .twoStars }.map(\.name)), ["Jônt", "minibar by José Andrés"])
        XCTAssertEqual(m.places.filter { $0.michelin == .oneStar }.count, 18)
        XCTAssertEqual(Set(m.places.map(\.id)).count, m.places.count, "ids are unique")
        for g in Guide.allCases where g.tag != nil {
            XCTAssertTrue(m.places.filter(g.includes).allSatisfy(\.handChecked), "\(g.title) lists only hand-checked places")
        }
        XCTAssertTrue(m.places.contains { $0.name == "Ben's Chili Bowl" && $0.jamesBeardLabel == "America's Classic" })
        XCTAssertGreaterThan(m.pouringCount, 1_000, "places with their own live ABCA on-premises license")
        XCTAssertGreaterThan(m.count(.patios), 200)
        XCTAssertEqual(Set(m.places.compactMap(\.county)).subtracting((1...8).map { "Ward \($0)" }), [], "every area is one of the 8 wards")
        XCTAssertTrue(m.places.allSatisfy { $0.coordinate.map { DCOutline.contains($0) } ?? false }, "every place is inside the District")
    }

    /// No Google-derived number anywhere in what the app bundles: Oregon and South Carolina once shipped a google21_open calibration key.
    /// Every key of every bundled JSON file is checked, not just the places.
    func testNoGoogleDerivedKeyInAnyBundledFile() throws {
        let urls = try XCTUnwrap(Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil))
        XCTAssertGreaterThanOrEqual(urls.count, 2)
        for url in urls {
            let keys = GoogleKeys.keys(in: try JSONSerialization.jsonObject(with: Data(contentsOf: url)))
            XCTAssertEqual(GoogleKeys.flagged(keys), [], "\(url.lastPathComponent) ships a Google-style key")
        }
    }

    func testGoogleKeyGuardCatchesABrokenCopy() throws {
        let broken: [String: Any] = ["calibration": ["DC": ["groups": ["google21_open": ["n": 1]]]], "places": [["id": "x", "rating": 4.5, "n": "A"]]]
        XCTAssertEqual(Set(GoogleKeys.flagged(GoogleKeys.keys(in: broken))), ["google21_open", "rating"])
        XCTAssertEqual(GoogleKeys.flagged(["n", "liq", "pt", "groups", "official"]), [], "ordinary keys aren't flagged")
    }

    /// Stable ids: md5(name + ~100 m cell)[:12], never a row number; the bundled detail file decodes and its ids are core ids.
    func testIdsAndBundledDetailFiles() async throws {
        let m = AppModel(defaults: UserDefaults(suiteName: "ids-\(UUID().uuidString)")!)
        await m.load()
        XCTAssertTrue(m.places.allSatisfy { $0.id.count >= 12 && $0.id.prefix(12).allSatisfy(\.isHexDigit) && $0.id.dropFirst(12).allSatisfy { $0 == "x" } })
        let ids = Set(m.places.map(\.id))
        var licensed = 0, alcohol = 0
        for region in Set(m.places.compactMap(\.region)) {
            let url = try XCTUnwrap(Bundle.main.url(forResource: "detail-" + AppModel.regionSlug(region), withExtension: "json"), region)
            let d = try JSONDecoder().decode([String: PlaceDetail].self, from: Data(contentsOf: url))
            XCTAssertTrue(Set(d.keys).isSubset(of: ids), "\(region) detail ids are core ids")
            licensed += d.values.filter { $0.licenses.contains { $0.source == "DLCP business license" && $0.id != nil } }.count
            alcohol += d.values.filter { $0.licenses.contains(where: \.isAlcohol) }.count
        }
        XCTAssertGreaterThan(licensed, 1_500, "places carry their DLCP license number")
        XCTAssertGreaterThan(alcohol, 1_000, "places carry their ABCA license number")
    }

    func testBundledDataGuards() async throws {
        let m = AppModel(defaults: UserDefaults(suiteName: "guards-\(UUID().uuidString)")!)
        await m.load()
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        XCTAssertEqual(DataGuards.adultVenues(m.places), [], "no strip club under its name")
        XCTAssertEqual(DataGuards.badWebsites(try DataGuards.bundledLinks(m.places)), [], "no directory, Google or news page as a restaurant's website")
        XCTAssertEqual(DataGuards.malformedWebsites(try DataGuards.bundledLinks(m.places, raw: true)), [], "every website is one link, with no spaces and no map link")
        XCTAssertEqual(DataGuards.badNames(m.places), [], "no visible name ending in \u{201C} the\u{201D} or \u{201C} of\u{201D}, or just \u{201C}The\u{201D}")
        XCTAssertEqual(DataGuards.legalNames(m.places), [], "no license holder entity name (\u{201C}… LLC\u{201D}) shown as a place's name")
        XCTAssertEqual(DataGuards.nonRestaurants(m.places), [], "no nail salon, senior home, gun store or gas station among the restaurants")
    }

    /// Each guard above fires on a copy of the bundled data broken the way QA found it elsewhere: a guard that can't fail guards nothing.
    func testGuardsCatchABrokenCopy() async throws {
        let raw = try Data(contentsOf: Bundle.main.url(forResource: "places", withExtension: "json")!)
        var file = try XCTUnwrap(JSONSerialization.jsonObject(with: raw) as? [String: Any])
        var places = try XCTUnwrap(file["places"] as? [[String: Any]])
        let idx = places.indices.filter { places[$0]["v"] == nil }.prefix(6).map { $0 }
        places[idx[2]]["n"] = "Baby Dolls Gentlemen's Club"
        places[idx[3]]["n"] = "Kitchen the"
        places[idx[4]]["n"] = "CAPITOL HILL HOSPITALITY GROUP LLC"
        places[idx[5]]["n"] = "Tipsy Nails & Spa"
        file["places"] = places
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("places-broken.json")
        try JSONSerialization.data(withJSONObject: file).write(to: url)
        let m = AppModel(defaults: UserDefaults(suiteName: "broken-\(UUID().uuidString)")!)
        await m.load(from: url)
        XCTAssertTrue(m.isLoaded, m.loadError ?? "")
        let id = idx.map { places[$0]["id"] as? String }
        func caught(_ found: [String], _ i: Int, _ what: String) {
            XCTAssertTrue(found.contains { $0.contains("[\(id[i] ?? "?")]") }, "the guard missed \(what)")
        }
        let links = [(name: "A", id: "x1", url: "https://www.yelp.com/biz/some-place"), (name: "B", id: "x2", url: "https://www.washingtonian.com/2026/05/01/best-cheap-eats/"),
                     (name: "C", id: "x3", url: "https://smart.com/menu")]
        XCTAssertEqual(DataGuards.badWebsites(links).count, 2, "the guard catches a Yelp page and a news story, and not smart.com")
        let fields = [(name: "D", id: "x4", url: "https://a.example.com https://b.example.com"), (name: "E", id: "x5", url: "https://a.example.com,https://b.example.com"),
                      (name: "F", id: "x6", url: "www.a.example.com/www.b.example.com"), (name: "G", id: "x7", url: "https://maps.app.goo.gl/AbC123"),
                      (name: "H", id: "x8", url: "https://www.google.com/maps/place/Ben's+Chili+Bowl"), (name: "I", id: "x9", url: "https://maps.apple.com/?q=Keren"),
                      (name: "J", id: "x10", url: "https://cafe.example/menu?a=1&b=2"), (name: "K", id: "x11", url: "goodstuffeatery.com"),
                      (name: "L", id: "x12", url: "https://www.waze-cafe.example/")]
        XCTAssertEqual(DataGuards.malformedWebsites(fields).map { String($0.prefix(1)) }, ["D", "E", "F", "G", "H", "I"],
                       "the guard catches a space, two links run together and map links, and leaves a site's own query and a bare host alone")
        caught(DataGuards.adultVenues(m.places), 2, "a gentlemen's club")
        caught(DataGuards.badNames(m.places), 3, "\u{201C}Kitchen the\u{201D}")
        caught(DataGuards.legalNames(m.places), 4, "a license holder's entity name")
        caught(DataGuards.nonRestaurants(m.places), 5, "a nail salon shown as a restaurant")
    }
}

/// Checks on the bundled data, written as functions so testGuardsCatchABrokenCopy can prove each one fires.
enum DataGuards {
    /// directories, Google and news sites: matched on the link's host, so "smart.com" isn't "rt.com"
    static let badHosts = #"^https?://([^/?#]*\.)?(yelp\.com|business\.site|google\.com|groupon\.com|yellowpages\.com|tripadvisor\.com|washingtonpost\.com|washingtonian\.com|dcist\.com|wtop\.com|popville\.com|washingtoncitypaper\.com|washington\.org|eater\.com|rt\.com)([:/?#]|$)"#

    static func badWebsites(_ links: [(name: String, id: String, url: String)]) -> [String] {
        links.compactMap { l in
            guard l.url.range(of: badHosts, options: [.regularExpression, .caseInsensitive]) != nil else { return nil }
            return "\(l.name) [\(l.id)]: \(l.url)"
        }
    }

    /// map pins (Google, Apple, Bing, MapQuest, Waze) given as a restaurant's website, scheme or not
    static let mapLinks = #"(?i)^(?:https?://)?(?:[^/?#\s]*\.)?(?:maps\.app\.goo\.gl|goo\.gl/maps|g\.page|maps\.google\.[a-z.]+|google\.[a-z.]+/maps|maps\.apple\.com|mapquest\.com|waze\.com|bing\.com/maps)([:/?#]|$)"#
    /// a second link run on: another scheme, or another "www." that doesn't follow one
    static let secondLink = try! NSRegularExpression(pattern: #"(?i)https?://|(?<!://)(?<![\w.-])www\."#)

    /// QA 2026-10-28 (P1): a website is one link to the place's own site, with no spaces in it, and not a map pin. Checked on the raw
    /// field, since URL(string:) percent-encodes a space and would hide it.
    static func malformedWebsites(_ links: [(name: String, id: String, url: String)]) -> [String] {
        links.compactMap { l in
            let u = l.url
            let several = secondLink.numberOfMatches(in: u, range: NSRange(u.startIndex..., in: u)) > 1
            guard u.rangeOfCharacter(from: .whitespacesAndNewlines) != nil || several || u.range(of: mapLinks, options: .regularExpression) != nil else { return nil }
            return "\(l.name) [\(l.id)]: \(u)"
        }
    }

    /// every website link in the bundled region detail files, with its place's name: as the app opens it (https:// added to a bare
    /// host), or with `raw` as the file holds it
    static func bundledLinks(_ places: [Place], raw: Bool = false) throws -> [(name: String, id: String, url: String)] {
        let names = Dictionary(places.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        var out: [(name: String, id: String, url: String)] = []
        for region in Set(places.compactMap(\.region)) {
            guard let url = Bundle.main.url(forResource: "detail-" + AppModel.regionSlug(region), withExtension: "json") else { continue }
            for (id, d) in try JSONDecoder().decode([String: PlaceDetail].self, from: Data(contentsOf: url)) {
                if let w = raw ? d.w : d.website?.absoluteString { out.append((names[id] ?? "?", id, w)) }
            }
        }
        return out
    }

    static let adultNames = #"\bnude\b|adult book ?store|gentlem[ae]n['’]?s club|strip club|exotic dancer|\bmen['’]?s club|rick['’]?s cabaret|xtc cabaret|baby dolls|spearmint rhino|bikini bar|pt['’]?s showclub|showgirls|centerfolds|treasures? gentlem"#

    /// every permit or license number in the bundled region detail files, by place id
    static func bundledLicenses(_ places: [Place]) throws -> [String: [String]] {
        var out: [String: [String]] = [:]
        for region in Set(places.compactMap(\.region)) {
            guard let url = Bundle.main.url(forResource: "detail-" + AppModel.regionSlug(region), withExtension: "json") else { continue }
            for (id, d) in try JSONDecoder().decode([String: PlaceDetail].self, from: Data(contentsOf: url)) where !d.licenses.isEmpty {
                out[id] = d.licenses.compactMap(\.id)
            }
        }
        return out
    }

    static func adultVenues(_ places: [Place]) -> [String] {
        places.filter { $0.name.range(of: adultNames, options: [.regularExpression, .caseInsensitive]) != nil }.map { "\($0.name) [\($0.id)]" }
    }

    /// a name cut off after "the" or "of" ("Kitchen the", "Wines of") or nothing but "The", among the places shown by default
    static func badNames(_ places: [Place]) -> [String] {
        places.filter { p in
            let n = p.name.trimmingCharacters(in: .whitespaces).lowercased()
            return !p.isVenue && (n.hasSuffix(" the") || n.hasSuffix(" of") || n == "the")
        }.map { "\($0.name) [\($0.id)]" }
    }

    /// a license holder (owner) is never shown; a business name that's still a legal entity shouldn't be either
    static let legalSuffix = #"\b(llc|l\.l\.c|inc|corp|corporation)\.?$"#

    static func legalNames(_ places: [Place]) -> [String] {
        places.filter { !$0.isVenue && $0.name.range(of: legalSuffix, options: [.regularExpression, .caseInsensitive]) != nil }
            .map { "\($0.name) [\($0.id)]" }
    }

    /// businesses that aren't places to eat, among the places shown by default
    static let nonRestaurantNames = #"\bnails?\b|assisted living|gun (?:club|range|shop|store)|shooting range|firearms|petroleum|\bauto (?:repair|parts)\b"#

    static func nonRestaurants(_ places: [Place]) -> [String] {
        places.filter { !$0.isVenue && $0.name.range(of: nonRestaurantNames, options: [.regularExpression, .caseInsensitive]) != nil }
            .map { "\($0.name) [\($0.id)]" }
    }
}

/// pipeline/website_blocklist.json (hacked, taken-over, expired or another business's sites, confirmed by hand in the link sweeps):
/// no link on it may ship in any field of any JSON file the app bundles. The 2026-10-19 QA found the export had only filtered the
/// website field, or nothing, so hijacked links were still in the bundle. Read from the repo, so a new entry needs no code change.
final class LinkBlocklistTests: XCTestCase {
    func testNoBlocklistedLinkInBundledData() throws {
        let entries = try LinkBlocklist.entries()
        XCTAssertFalse(entries.isEmpty, "the blocklist is missing or empty")
        let files = LinkBlocklist.bundledJSON()
        XCTAssertFalse(files.isEmpty, "no bundled JSON found")
        var hits: [String] = []
        for url in files {
            let text = try String(contentsOf: url, encoding: .utf8)
            hits += LinkBlocklist.hits(in: text, entries).map { "\(url.lastPathComponent): \($0)" }
        }
        XCTAssertEqual(hits, [], "blocklisted links in the app's bundled data")
    }

    /// The guard fires on a copy of the bundled data broken three ways: a blocklisted domain, its subdomain, and a "url" entry.
    func testBlocklistGuardCatchesABrokenCopy() throws {
        let entries = try LinkBlocklist.entries()
        let file = try XCTUnwrap(LinkBlocklist.bundledJSON().max { (try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0 < (try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0 })
        let text = try String(contentsOf: file, encoding: .utf8)
        let domain = try XCTUnwrap(entries.first { ($0["match"] as? String ?? "domain") == "domain" }?["domain"] as? String)
        let fake: [[String: Any]] = entries + [["match": "url", "url": "https://example.org/hacked-page"]]
        let before = LinkBlocklist.hits(in: text, fake).count
        let broken = text + "{\"w\":\"https://www.\(domain)/menu\"}{\"src\":\"http://shop.\(domain)/\"}{\"w\":\"https://example.org/hacked-page/\"}"
        XCTAssertEqual(LinkBlocklist.hits(in: broken, fake).count, before + 3, "a domain, a subdomain and a url entry are all caught")
        XCTAssertEqual(LinkBlocklist.hits(in: "{\"w\":\"https://not\(domain)/\"}", entries), [], "a host that only ends with the domain's letters isn't it")
    }
}

enum LinkBlocklist {
    static func entries() throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("pipeline/website_blocklist.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: Any]])
    }

    /// every .json file in the app bundle, subfolders included
    static func bundledJSON() -> [URL] {
        let root = Bundle.main.bundleURL
        let all = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return all.filter { $0.pathExtension == "json" && !$0.path.contains("/PlugIns/") }
    }

    private static func host(_ u: URLComponents) -> String {
        var h = (u.host ?? "").lowercased()
        if h.hasSuffix(".") { h.removeLast() }
        return h.hasPrefix("www.") ? String(h.dropFirst(4)) : h
    }

    private static func trimmedPath(_ p: String) -> String { p.hasSuffix("/") ? String(p.dropLast()) : p }

    /// the links in a JSON text that an entry covers: a "domain" entry its domain and subdomains, a "url" entry that page only
    static func hits(in text: String, _ entries: [[String: Any]]) -> [String] {
        let t = text.replacingOccurrences(of: "\\/", with: "/")
        let rx = try! NSRegularExpression(pattern: #"https?://[^"\s\\]+"#, options: [.caseInsensitive])
        return rx.matches(in: t, range: NSRange(t.startIndex..., in: t)).compactMap { m -> String? in
            let s = String(t[Range(m.range, in: t)!])
            guard let u = URLComponents(string: s) else { return nil }
            let h = host(u)
            for e in entries {
                if (e["match"] as? String ?? "domain") == "url" {
                    guard let v = URLComponents(string: e["url"] as? String ?? "") else { continue }
                    if !h.isEmpty && h == host(v) && trimmedPath(u.path) == trimmedPath(v.path) { return s }
                } else {
                    var d = (e["domain"] as? String ?? "").lowercased()
                    if let r = d.range(of: "://") { d = String(d[r.upperBound...]) }
                    d = String(d.split(separator: "/").first ?? "")
                    if d.hasPrefix("www.") { d = String(d.dropFirst(4)) }
                    if !d.isEmpty && (h == d || h.hasSuffix("." + d)) { return s }
                }
            }
            return nil
        }
    }
}

/// QA 2026-10-19, P1 3a: the support address is nick@eatsranked.com (Nick, 2026-10-12). The old Gmail address must not come back
/// anywhere in the app's source or bundled files.
final class SupportEmailTests: XCTestCase {
    func testSupportEmailIsEatsRanked() {
        XCTAssertEqual(Links.supportEmail, "nick@eatsranked.com")
    }

    func testNoGmailInAppSource() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("DCEats")
        XCTAssertGreaterThan(SupportEmailScan.textFiles(under: root).count, 5, "the app's source folder wasn't found")
        XCTAssertEqual(SupportEmailScan.hits(under: root), [], "the app's source still has a Gmail address")
    }

    /// The guard fires on a broken copy: a folder with one planted Gmail address.
    func testGmailGuardCatchesABrokenCopy() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("App"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try "static let supportEmail = \"someone@GMAIL.com\"\n".write(to: dir.appendingPathComponent("App/Links.swift"), atomically: true, encoding: .utf8)
        try "{\"ok\": \"nick@eatsranked.com\"}".write(to: dir.appendingPathComponent("App/data.json"), atomically: true, encoding: .utf8)
        XCTAssertEqual(SupportEmailScan.hits(under: dir), ["App/Links.swift"])
    }
}

enum SupportEmailScan {
    static let textExtensions: Set<String> = ["swift", "plist", "json", "strings", "xcstrings", "xcprivacy", "md", "txt", "html", "entitlements"]

    static func textFiles(under root: URL) -> [URL] {
        let all = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return all.filter { textExtensions.contains($0.pathExtension.lowercased()) }
    }

    /// paths (relative to root) of text files that mention gmail.com, in any case
    static func hits(under root: URL) -> [String] {
        let base = root.resolvingSymlinksInPath().path + "/"
        return textFiles(under: root).compactMap { url in
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  text.range(of: "gmail.com", options: .caseInsensitive) != nil else { return nil }
            return url.resolvingSymlinksInPath().path.replacingOccurrences(of: base, with: "")
        }.sorted()
    }
}

/// QA 2026-10-19, P1 #13: outbound links ship without tracking tags (ref=google, referrer=google_food_ordering, cn_channel, utm_* …).
/// pipeline/tracking_params.py strips them in the export; these are the same rules, including QA 2026-10-28's (P1 #4): tags after "#",
/// tags written into the path, links stored without a scheme, and Klaviyo's _kx.
final class TrackingParamTests: XCTestCase {
    func testNoTrackingParametersInBundledLinks() throws {
        let files = TrackingParams.bundledJSON()
        XCTAssertFalse(files.isEmpty, "no bundled JSON found")
        var hits: [String] = []
        for url in files {
            let text = try String(contentsOf: url, encoding: .utf8)
            hits += TrackingParams.tracked(in: text).map { "\(url.lastPathComponent): \($0)" }
        }
        XCTAssertEqual(hits, [], "links with tracking parameters in the app's bundled data")
    }

    /// The guard fires on a broken copy (four kinds of tracking tag, one in escaped JSON) and leaves a store's own parameters alone.
    func testTrackingGuardCatchesABrokenCopy() {
        let broken = #"[{"w":"https:\/\/places.example.com\/menu?ref=google"},{"w":"https://a.example/?utm_source=gmb&store=4"},"#
            + #"{"w":"https://b.example/x?referrer=google_food_ordering"},{"w":"https://c.example/order/1?cn_channel=cn_google"}]"#
        XCTAssertEqual(TrackingParams.tracked(in: broken).count, 4)
        let clean = #"[{"w":"https://order.example.com/menu?restaurantId=51&location=7"},{"w":"https://shop.example.com/?cid=12&ref=gs"}]"#
        XCTAssertEqual(TrackingParams.tracked(in: clean), [])
        // QA 2026-10-28: after "#" (Hard Rock DC's Yext tag) or in a route after "#", in the path, without a scheme, and _kx
        let broken2 = #"[{"w":"https:\/\/www.hardrockcafe.com\/location\/washington-dc#utm_source=rest_of_network&utm_medium=Yext"},"#
            + #"{"w":"https://order.example.com/#/menu?utm_source=fb&table=4"},"#
            + #"{"w":"https://www.snoozeeatery.com/restaurant/georgia/alpharetta/utm_source=Facebook&utm_medium=BusinessListing"},"#
            + #"{"w":"instagram.com\/sharks1413_macon?igshid=NjNlMDhmYTc%3D"},"#
            + #"{"w":"https://paulthomaschocolates.com/pages/free-tasting-event?_kx=aSsBlo5n7gs8.V26kig%3Futm_source%3Dfacebook"}]"#
        XCTAssertEqual(TrackingParams.tracked(in: broken2).count, 5)
        // a page anchor, a single-page app's route and its own query, a path that happens to hold "=", a scheme-less link's own query
        let clean2 = #"[{"w":"https://example.com/#menu"},{"w":"https://togoorder.com/web/1754#/"},"#
            + #"{"w":"https://order.example.com/#/store?id=9"},{"w":"https://example.com/p/id=5"},{"w":"www.example.com/menu?page=2"}]"#
        XCTAssertEqual(TrackingParams.tracked(in: clean2), [])
    }
}

enum TrackingParams {
    /// tracking by name, whatever the value
    static let keys = try! NSRegularExpression(pattern: #"^(?:utm[_-].*|gclid|gbraid|wbraid|dclid|fbclid|msclkid|mc_cid|mc_eid|_ga|_gl|_kx|igsh|"#
        + #"igshid|mibextid|srsltid|cn_channel|y_source|rwg_token|olonwp|ost_redirect_attribution|cmpid|yext_?.*)$"#, options: [.caseInsensitive])
    /// tracking only with these values
    static let values: [String: String] = ["ref": #"^(?:google|gmb|gbp|yext|bookmarks)\b"#, "referrer": "^google",
                                           "source": #"^(?:google|gmb|gbp|yext)\b"#, "cid": "^RF:YXT", "cmp": "^OKC-"]

    /// every .json file in the app bundle, subfolders included
    static func bundledJSON() -> [URL] {
        let all = FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return all.filter { $0.pathExtension == "json" && !$0.path.contains("/PlugIns/") }
    }

    static func isTracking(_ key: String, _ value: String) -> Bool {
        let k = key.trimmingCharacters(in: .whitespaces)
        if keys.firstMatch(in: k, range: NSRange(k.startIndex..., in: k)) != nil { return true }
        guard let pattern = values[k.lowercased()] else { return false }
        return value.trimmingCharacters(in: .whitespaces).range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// links in a JSON or HTML text that still carry a tracking tag (tracking_params.py's tracked()): with a scheme, or a bare host and
    /// path ("instagram.com/x?igshid=…", shown with https:// added)
    static func tracked(in text: String) -> [String] {
        let t = text.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "&amp;", with: "&")
        let rx = try! NSRegularExpression(pattern: #"(?i)https?://[^\s"'<>\\]+|(?<![\w/.:@-])(?:[a-z0-9-]+\.)+[a-z]{2,}/[^\s"'<>\\]*"#)
        return rx.matches(in: t, range: NSRange(t.startIndex..., in: t)).compactMap { m -> String? in
            let s = String(t[Range(m.range, in: t)!])
            return carriesTracking(s) ? s : nil
        }
    }

    /// a tracking pair in the query, after "#" ("#utm_source=…", or a route's own query: "#/menu?utm_source=…"), or in a path segment
    /// written as "k=v&…" (".../alpharetta/utm_source=Facebook&utm_medium=BusinessListing")
    static func carriesTracking(_ url: String) -> Bool {
        let hash = url.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let fragment = hash.count > 1 ? hash[1] : ""
        let q = hash[0].split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        if q.count > 1, hasTrackingPair(q[1]) { return true }
        if fragment.contains("="), let tail = fragment.split(separator: "?", omittingEmptySubsequences: false).last, hasTrackingPair(tail) {
            return true
        }
        return q[0].split(separator: "/").contains { $0.contains("=") && hasTrackingPair($0) }
    }

    /// "k=v&k2=v2" holds a tracking pair
    static func hasTrackingPair(_ params: Substring) -> Bool {
        func decoded(_ s: Substring) -> String { String(s).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String(s) }
        return params.split(separator: "&").contains { part in
            let kv = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            return isTracking(decoded(kv[0]), kv.count > 1 ? decoded(kv[1]) : "")
        }
    }
}

/// Keys that would mean Google-derived data (ratings, reviews, price levels, 2021 snapshot matches) in a bundled file.
enum GoogleKeys {
    static let pattern = #"(?i)google|gmap|g21|in21|closed21|rating|review|price_level|price_est|stars"#

    static func keys(in json: Any) -> [String] {
        if let d = json as? [String: Any] { return d.keys + d.values.flatMap(keys(in:)) }
        if let a = json as? [Any] { return a.flatMap(keys(in:)) }
        return []
    }

    static func flagged(_ keys: [String]) -> [String] {
        Array(Set(keys.filter { $0.range(of: pattern, options: .regularExpression) != nil })).sorted()
    }
}
