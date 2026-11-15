import Foundation

// MARK: - CountryModel
struct CountryModel: Codable {
    let status: String
    let statusCode: Int
    let version, access: String
    let total, offset, limit: Int
    let data: [String: Datum]

    enum CodingKeys: String, CodingKey {
        case status
        case statusCode = "status-code"
        case version, access, total, offset, limit, data
    }
}

// MARK: - Datum
struct Datum: Codable {
    let country: String
    let region: Region
}

// MARK: - Region
// Region names come from the service and are not a closed set.
struct Region: RawRepresentable, Codable, Hashable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static let africa = Region(rawValue: "Africa")
    static let antarctic = Region(rawValue: "Antarctic")
    static let asia = Region(rawValue: "Asia")
    static let centralAmerica = Region(rawValue: "Central America")
}
