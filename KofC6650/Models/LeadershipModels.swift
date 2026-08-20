import Foundation

struct LeadershipContact: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let email: String?
}

/// Static roster from kofc6650.org/about-us/officers and .../directors.
/// Not fetched at runtime -- this changes rarely enough that a manual
/// update here (matching the website) is simpler than a backend endpoint.
/// Joe Healey (former Chancellor) intentionally omitted -- deceased;
/// Brendan Sibilio moved from Advocate to Chancellor to fill the seat.
/// Vacant seats (Vocations Chairman, Public Relations, Advocate)
/// intentionally omitted -- nobody to contact.
enum LeadershipDirectory {
    static let officers: [LeadershipContact] = [
        LeadershipContact(name: "Nate Miranda", title: "Grand Knight", email: "grandknight@kofc6650.org"),
        LeadershipContact(name: "David Erdman", title: "Deputy Grand Knight", email: "deputygk@kofc6650.org"),
        LeadershipContact(name: "Brendan Sibilio", title: "Chancellor", email: "chancellor@kofc6650.org"),
        LeadershipContact(name: "Deacon Brian Phillips", title: "Chaplain", email: "bphillips@stmcary.org"),
        LeadershipContact(name: "Tom Navarre", title: "Financial Secretary", email: "FS@kofc6650.org"),
        LeadershipContact(name: "Bill Wester", title: "Treasurer", email: "treasurer@kofc6650.org"),
        LeadershipContact(name: "Sal Morra", title: "Recorder", email: "recorder@kofc6650.org"),
        LeadershipContact(name: "Scott Ramage", title: "Lecturer", email: "newsletter@kofc6650.org"),
        LeadershipContact(name: "Andrew Reynolds", title: "3 Year Trustee", email: "trustee3@kofc6650.org"),
        LeadershipContact(name: "Will McGowan", title: "2 Year Trustee", email: "trustee2@kofc6650.org"),
        LeadershipContact(name: "Joe Umbra", title: "1 Year Trustee", email: "trustee1@kofc6650.org"),
        LeadershipContact(name: "Joe Crowe", title: "District Deputy", email: "dd5@kofcnc.org"),
        LeadershipContact(name: "Rob Crews", title: "Warden", email: "warden@kofc6650.org"),
        LeadershipContact(name: "Louis Prosser", title: "Inside Guard", email: "insideguard@kofc6650.org"),
        LeadershipContact(name: "Dan Gonzales", title: "Outside Guard", email: "og@kofc6650.org"),
    ]

    static let directors: [LeadershipContact] = [
        LeadershipContact(name: "Chris Peffley", title: "Faith Director", email: "church@kofc6650.org"),
        LeadershipContact(name: "John Summers", title: "Community Director", email: "community@kofc6650.org"),
        LeadershipContact(name: "Ken Wondra", title: "Culture of Life Director", email: "cultureoflife@kofc6650.org"),
        LeadershipContact(name: "Bob Muzzi", title: "Family Director", email: "family@kofc6650.org"),
        LeadershipContact(name: "Ralph Becker", title: "Digital Committee", email: "digitialcommitteechair@kofc6650.org"),
        LeadershipContact(name: "Vito Stellato", title: "Hospitality", email: "hospitality@kofca2446.org"),
        LeadershipContact(name: "David Erdman", title: "Membership and Retention Director", email: "membership@kofc6650.org"),
        LeadershipContact(name: "Timothy Logan", title: "LAMB Director", email: "lamb@kofc6650.org"),
        LeadershipContact(name: "Wil Trower", title: "Cor Director", email: "cor@kofc6650.org"),
        LeadershipContact(name: "Joey Owens", title: "Field Agent", email: "Joseph.Owens@KofC.org"),
        LeadershipContact(name: "Will McGowan", title: "Round Table – MTCC", email: "rtchairmt@kofc6650.org"),
        LeadershipContact(name: "Tom Maher", title: "Round Table – STA", email: "rtchairsta@kofc6650.org"),
        LeadershipContact(name: "Paul Kondor", title: "Round Table – STM", email: "rtchairstm@kofc6650.org"),
    ]
}
