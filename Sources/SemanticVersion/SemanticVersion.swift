import Foundation

//
// https://semver.org
//
// MARK: -
public protocol SemanticVersionable {
    var version:SemanticVersion { get }
}
// MARK: -
/// A type that can represent a semantic version.
public struct SemanticVersion {

    // MARK: Public
    /// Major version number.
    ///
    /// Rule 1: Software using Semantic Versioning MUST declare a public API. This API could be declared in the code itself or exist strictly in documentation. However it is done, it SHOULD be precise and comprehensive.
    ///
    /// Rule 2: A normal version number MUST take the form X.Y.Z where X, Y, and Z are non-negative integers, and MUST NOT contain leading zeroes. X is the major version, Y is the minor version, and Z is the patch version. Each element MUST increase numerically.
    ///
    /// Rule 3: Once a versioned package has been released, the contents of that version MUST NOT be modified. Any modifications MUST be released as a new version.
    ///
    /// Rule 4: Major version zero (0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT be considered stable.
    ///
    /// Rule 5: Version 1.0.0 defines the public API. The way in which the version number is incremented after this release is dependent on this public API and how it changes.
    ///
    /// Rule 6: Patch version Z (x.y.Z | x > 0) MUST be incremented if only backwards compatible bug fixes are introduced. A bug fix is defined as an internal change that fixes incorrect behavior.
    ///
    /// Rule 7: Minor version Y (x.Y.z | x > 0) MUST be incremented if new, backwards compatible functionality is introduced to the public API. It MUST be incremented if any public API functionality is marked as deprecated. It MAY be incremented if substantial new functionality or improvements are introduced within the private code. It MAY include patch level changes. Patch version MUST be reset to 0 when minor version is incremented.
    ///
    /// Rule 8: Major version X (X.y.z | X > 0) MUST be incremented if any backwards incompatible changes are introduced to the public API. It MAY also include minor and patch level changes. Patch and minor version MUST be reset to 0 when major version is incremented.

    public var major:UInt = 0
    /// Minor version number.
    ///
    /// See more on `major`.
    public var minor:UInt = 0
    /// Patch version number.
    ///
    /// See more on `major`.
    public var patch:UInt = 0
    /// Pre-release identifiers.
    ///
    /// Rule 9: A pre-release version MAY be denoted by appending a hyphen and a series of dot separated identifiers immediately following the patch version. Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty. Numeric identifiers MUST NOT include leading zeroes. Pre-release versions have a lower precedence than the associated normal version. A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility requirements as denoted by its associated normal version.
    ///
    /// Rule 11: Precedence refers to how versions are compared to each other when ordered. Precedence MUST be calculated by separating the version into major, minor, patch and pre-release identifiers in that order (Build metadata does not figure into precedence). Precedence is determined by the first difference when comparing each of these identifiers from left to right as follows: Major, minor, and patch versions are always compared numerically. Example: 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1. When major, minor, and patch are equal, a pre-release version has lower precedence than a normal version. Example: 1.0.0-alpha < 1.0.0. Precedence for two pre-release versions with the same major, minor, and patch version MUST be determined by comparing each dot separated identifier from left to right until a difference is found as follows: identifiers consisting of only digits are compared numerically and identifiers with letters or hyphens are compared lexically in ASCII sort order. Numeric identifiers always have lower precedence than non-numeric identifiers. A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.
    private (set) public var preReleaseIdentifiers:[String]?
    /// Build metadata identifiers.
    ///
    /// Rule 10: Build metadata MAY be denoted by appending a plus sign and a series of dot separated identifiers immediately following the patch or pre-release version. Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty. Build metadata MUST be ignored when determining version precedence. Thus two versions that differ only in the build metadata, have the same precedence.
    private (set) public var buildMetadataIdentifiers:[String]?
    /// Deprecated
    ///
    /// Deprecated, use description instead.
    @available(*, deprecated, renamed: "description")
    public var versionString:String {
        let v = [major, minor, patch].map { "\($0)" }.joined(separator: ".")
        let r = (preReleaseIdentifiers ?? []).joined(separator: ".")
        let b = (buildMetadataIdentifiers ?? []).joined(separator: ".")
        return v + (r.isEmpty ? "" : "-\(r)") + (b.isEmpty ? "" : "+\(b)")
    }
    // MARK: -
    // MARK: Initialisation
    /// Returns an instance representing a semantic version 0.0.0
    public init() {}
    public init(_ major: UInt, _ minor: UInt, _ patch: UInt) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    public init?(_ major: UInt, _ minor: UInt, _ patch: UInt, _ preReleaseIdentifiers: [String]?) {
        self.init(major, minor, patch)
        // init will ignore tokens with invalid characters
        guard _validateIdentifiers(preReleaseIdentifiers) else { return nil }
        self.preReleaseIdentifiers = preReleaseIdentifiers
    }
    public init?(_ major: UInt, _ minor: UInt, _ patch: UInt,
                _ preReleaseIdentifiers: [String]?,
                _ buildMetadataIdentifiers: [String]?) {
        self.init(major, minor, patch)
        // init will ignore tokens with invalid characters
        guard _validateIdentifiers(preReleaseIdentifiers) else { return nil }
        self.preReleaseIdentifiers = preReleaseIdentifiers
        guard _validateIdentifiers(buildMetadataIdentifiers) else { return nil }
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }
    public init(major: UInt, minor: UInt, patch: UInt) {
        self.init(major, minor, patch)
    }
    public init?(major: UInt, minor: UInt, patch: UInt, preReleaseIdentifiers: [String]?) {
        self.init(major, minor, patch)
        // init will ignore tokens with invalid characters
        guard _validateIdentifiers(preReleaseIdentifiers) else { return nil }
        self.preReleaseIdentifiers = preReleaseIdentifiers
    }
    public init?(major: UInt, minor: UInt, patch: UInt,
                preReleaseIdentifiers: [String]?,
                buildMetadataIdentifiers: [String]?) {
        self.init(major, minor, patch)
        // init will ignore tokens with invalid characters
        guard _validateIdentifiers(preReleaseIdentifiers) else { return nil }
        self.preReleaseIdentifiers = preReleaseIdentifiers
        guard _validateIdentifiers(buildMetadataIdentifiers) else { return nil }
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }
    // MARK: -
    // MARK: Internal
    internal func _validateIdentifiers(_ identifiers:[String]?) -> Bool {
        // identifiers == nil -> ok
        guard let identifiers = identifiers else {
            return true
        }
        // - Don't allow empty identifiers []
        // - Require identifiers to be either valid numeric identifiers
        //   or valid alphanumeric or hyphen identifiers [0-9A-Za-z-]
        //
        // NOTE: String "0123" is valid alphanumeric identifier, but
        // as it contains only numbers, it will be treated as numeric
        // identifier. And and as it has a leading zero, it becomes
        // a non-valid identifier.

        return identifiers.isEmpty ? false : identifiers.allSatisfy({ (s) in
            guard _isValidNumericToken(s) == true else {
                // not a "pure" numeric identifier
                // is it [0-9A-Za-z-] identifier?
                return _isAlphaNumericOrHyphenToken(s) && // [0-9A-Za-z-]
                    _isNumericToken(s) == false // pure numeric identifiers are no longer accepted
            }
            return true // Was valid numeric identifier
        })
    }

    internal func _isAlphaNumericOrHyphenToken(_ token:String) -> Bool {
        return !token.isEmpty &&
            CharacterSet(charactersIn: token)
                .isSubset(of: validIdentifierChars)
    }

    internal func _isValidNumericToken(_ token:String) -> Bool {
        // Only numbers allowed
        // No leading zeroes allowed
        guard _isNumericToken(token) else {
            return false
        }
        // Extract all zeros from the beginning
        let leadingZeroes = token.prefix(while: { (char) -> Bool in char == "0" })
        // One zero "0" is ok, two or more zeros "00", means we have leading zeros -> not ok
        if leadingZeroes.count >= 1 && token.count > 1 {
            return false
        }
        // Do not allow empty identifiers
        return !token.isEmpty
    }
}
internal func _isNumericToken(_ token:String) -> Bool {
    return CharacterSet(charactersIn: token)
        .isSubset(of: CharacterSet(charactersIn: "1234567890"))
}
// MARK: -
internal func semanticTokenArrayCompareLessThan(_ lhs:[String], _ rhs:[String]) -> Bool {

    for (l,r) in zip(lhs, rhs) {
        switch (_isNumericToken(l), _isNumericToken(r)) {
        case (true, true):
            guard let ul = UInt(l), let ur = UInt(r) else {
                fatalError("String to UInt conversion failed. Are these [\(l), \(r)] valid UInt values?")
            }
            if ul == ur { continue }
            else { return ul < ur }
        case (true, false): // lower
            return true
        case (false, true): // higher
            return false
        case (false, false):
            // Dilemma - semver rules states following...
            //
            // - identifiers with letters or hyphens are compared
            //   lexically in ASCII sort order -> [A-Za-z-]
            // - identifiers consisting of only digits are compared
            //   numerically -> [0-9]
            //
            // Interpreting above "strictly", it is unclear how
            // comparison should be done when identifier is
            // combination of letters, digits, hyphens -> [0-9A-Za-z-]
            //
            // Quickly thinking it would be easy to lean towards
            // lexical sort order. Identifier is "mixed" so lexical
            // sort order is what one would expect. This will lead to
            // following (pre-release identifiers of different versions):
            //
            // "rc9", "rc20", "rc100"
            // sorted lexically
            // "rc100", "rc20", "rc9"
            //
            // Above works ok, for single digit sorting, but as soon
            // as identifier digit count is > 2. Sort order becomes
            // unintuitive for humans.
            // Above can be solved by including proper amount of leading
            // zeroes in the identifier.
            // "rc009", "rc020", "rc100" will sort as expected.
            //
            // Or should dilemma be considered as a convenient loophole
            // to be innovative in this case and enable numeric(*) sort for
            // "mixed" content.
            //
            // (*) NSString.CompareOptions.numeric documentation states:
            //
            //     Numeric comparison only applies to the numerals
            //     in the string, not other characters that would
            //     have meaning in a numeric representation such
            //     as a negative sign, a comma, or a decimal point.
            //
            // Enabling numeric sort option would produce results
            // what most humans would expect.
            //
            // One can workaround the lexical sort issue by
            // introducing additional identifiers.
            //
            // rc1, ..., rc9, rc9.0, rc9.1, ..., rc9.9.0, ...
            //
            // But for humans, results are bit cumbersome.
            //
            // To avoid above issue in the first place, one should
            // release the first release candidate with following scheme:
            //
            // SemanticVersion(1,0,0,["rc", "1"]) // "1.0.0-rc.1"
            // ...
            // SemanticVersion(1,0,0,["rc", "28"]) // "1.0.0-rc.28"
            //
            // Above strategy would keep rc's sorted correctly at all
            // times as "digit" only identifiers are sorted numerically.
            // But, if one has made the initial mistake of releasing
            // the first rc as "rc1", there is no way to get back on the
            // proper scheme. The only option is to release before one
            // hits the 10 ;-)
            //
            // Decision: enable numeric sort option as it will
            // likely save some poor souls from the initial mistake
            // of releasing first release candidate as "rc1"
            // and not as "rc.1" or "rc001"


            #if SORT_OPTION_NONE
            let sortOptions:NSString.CompareOptions = []
            #else
            let sortOptions:NSString.CompareOptions = [.numeric]
            #endif
            switch l.compare(r, options: sortOptions) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            case .orderedSame: continue // No difference, go deeper
            }
        }
    }
    // No difference in identifiers. How about identifier count?
    // Rule 11: A larger set of pre-release fields has a higher precedence
    // than a smaller set, if all of the preceding identifiers are equal.
    return lhs.count < rhs.count
}
// MARK: -
// MARK: validIdentifierChars
/// Valid characters for pre-release and build metadata identifiers
///
/// ASCII letters `[0-9A-Za-z-]`
fileprivate let validIdentifierChars = CharacterSet(charactersIn: "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")
// MARK: -
// MARK: CustomStringConvertible
extension SemanticVersion : CustomStringConvertible {
    public var description: String {
        let v = [major, minor, patch].map { "\($0)" }.joined(separator: ".")
        let r = (preReleaseIdentifiers ?? []).joined(separator: ".")
        let b = (buildMetadataIdentifiers ?? []).joined(separator: ".")
        return v + (r.isEmpty ? "" : "-\(r)") + (b.isEmpty ? "" : "+\(b)")
    }
}
// MARK: Codable
extension SemanticVersion : Codable {}
// MARK: Hashable
extension SemanticVersion : Hashable {}
// MARK: Comparable, Equatable
extension SemanticVersion : Comparable, Equatable {
    public static func ==(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return (lhs < rhs) == false && (lhs > rhs) == false
    }
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major < rhs.major {
            return true
        }
        if lhs.major > rhs.major {
            return false
        }
        if lhs.major == rhs.major {
            // Next level
            if lhs.minor < rhs.minor {
                return true
            }
            if lhs.minor > rhs.minor {
                return false
            }
            if lhs.minor == rhs.minor {
                // Next level
                if lhs.patch < rhs.patch {
                    return true
                }
                if lhs.patch > rhs.patch {
                    return false
                }
            }
        }

        // Build metadata SHOULD be ignored when determining version precedence.
        // Thus two versions that differ only in the build metadata, have the
        // same precedence.
        if let lhsTokens = lhs.preReleaseIdentifiers {
            if let rhsTokens = rhs.preReleaseIdentifiers {
                // some, some => comapre
                let r = semanticTokenArrayCompareLessThan(lhsTokens, rhsTokens)
                return r
            }
            else {
                // some, nil =>
                // lhs is pre-release and rhs is non-pre-release
                // => rhs has higher precedence than lhs
                return true
            }
        }
        else {
            if let _ = rhs.preReleaseIdentifiers {
                // nil, some =>
                // lhs is non-pre-release and rhs is pre-release
                // => lhs has higher precedence than rhs
                return false
            }
            else {
                // nil, nil
                // lhs is non-pre-release and rhs is non-pre-release
                // => lhs and rhs version numbers are equal & both
                // are non-pre-releases, hence lhs is not < rhs
                return false
            }
        }
    }
}
// MARK: LosslessStringConvertible
extension SemanticVersion : LosslessStringConvertible {
    public init?(_ description: String) {

        // Initializing from a string allows an intuitive and natural way
        // to express a simple version.
        //
        // SemanticVersion("1.0.0-beta+debug") // "1.0.0-beta+debug"
        //
        // At the same time given string can be anything but a
        // version number and something which clearly doesn't follow
        // the defined format. In these cases returning nil and failing
        // is the right choise.
        //
        // SemanticVersion("Lorem ipsum...") // nil
        //
        // There are also cases where given string is close to
        // proper format, but is missing some piece(s) of data or
        // is othrevice "slightly" incorrectly formatted.
        //
        // SemanticVersion("1-alpha") // "1.0.0-alpha" ?
        // SemanticVersion("0+") // "0.0.0" with "" build metadata ?
        //
        // Following implementation tries to emulate
        //
        //      "a human intuitively and without thinking reading
        //       the given string as a valid version number".
        //


        // Match the empty initializer.
        // Initializing with empty string equals to SemanticVersion() -> 0.0.0
        if description.isEmpty {
            return // -> 0.0.0
        }


        // Separate the version digit segment from rest of the string.
        // "1.0.0-alpha+debug" -> "1.0.0"
        //      ^- is cut from here
        // Characters allowed in version digits.
        let versionDigitSet = CharacterSet(charactersIn: "1234567890.")
        let versionSegment = description.prefix { (c) -> Bool in
            c.unicodeScalars.allSatisfy({ versionDigitSet.contains($0) })
        }


        // Split version digit segment into (maximum) of maxVersionComponents
        // component array.
        //
        // "1.0.0" -> [Optional(1), Optional(0), Optional(0)]
        // "1.0.0.0" -> [Optional(1), Optional(0), Optional(0)]
        // "1..0" -> [Optional(1), Optional(0)]
        // "....1" -> [Optional(1)]
        let maxVersionComponents = 3
        let versionComponents = (versionSegment
            .split(separator: ".",
                   maxSplits: maxVersionComponents,
                   omittingEmptySubsequences: true)
            .map({UInt($0)}))
            .prefix(maxVersionComponents)


        // Create a version digit string from the version components.
        // Version is regarded as good and valid, if the re-created
        // version string equals to original version digit segment.
        //
        // "1.0.0" -> [Optional(1), Optional(0), Optional(0)] -> "1.0.0" -> OK
        // "1.0.0.0" -> [Optional(1), Optional(0), Optional(0)] -> "1.0.0" != "1.0.0.0" -> fail
        // "1..0" -> [Optional(1), Optional(0)] -> "1.0" != "1..0" -> fail
        // "....1" -> [Optional(1)] -> "1" != "....1" -> fail
        guard versionSegment == versionComponents.map({ "\($0 ?? 0)" }).joined(separator: ".") else {
            return nil
        }

        // Separate the pre-release identifier segment from the string.
        // That is a substring starting after the first dash (-) to the
        // end of string or up until the first plus (+) character.
        // "1.0.0-alpha+debug" -> "alpha"
        // "1.2.3+de-bug" -> ""
        let releaseSegment = description
            // Drop until the first plus (+) or dash (-) character.
            //     "1.0.0-alpha+debug" -> "-alpha+debug"
            //     "1.2.3+de-bug" -> ""
            .drop { (c) -> Bool in "-+".contains(c) == false }
            // Include everything up to the first plus (+).
            //     "-alpha+debug" -> "alpha+"
            //     "" -> ""
            .prefix { (c) -> Bool in  c != "+" }
            // remove plus (+) at the end.
            //     "alpha+" -> "alpha"
            //     "" -> ""
            .dropFirst()

        // Split pre-release identifier segment into component array
        // separated by dot (.) character. If resulting component
        // array is empty, assign nil instead of [].
        let releaseComponents = releaseSegment.isEmpty ? nil : releaseSegment.split(separator: ".").map { String($0) }


        // Split build metadata identifier segment into component array
        // separated by dot (.) character. If resulting component
        // array is empty, assign nil instead of [].
        let buildSegment = description
            // Drop until the first plus (+) character.
            //     "1.0.0-alpha+debug" -> "+debug"
            //     "1.2.3+de-bug" -> "+de-bug"
            .drop { (c) -> Bool in "+".contains(c) == false }
            // remove plus (+) at the beginning.
            //     "+debug" -> "debug"
            //     "+de-bug" -> "de-bug"
            .dropFirst()

        // Split build metadata identifier segment into component array
        // separated by dot (.) character. If resulting component
        // array is empty, assign nil instead of [].
        let buildComponents = buildSegment.isEmpty ? nil :  buildSegment.split(separator: ".").map { String($0) }



        // Initialize version digits
        switch versionComponents.count {
        case 1:
            guard let major = versionComponents[0] else { return nil }
            self.major = major
        case 2:
            guard let major = versionComponents[0] else { return nil }
            guard let minor = versionComponents[1] else { return nil }
            self.major = major
            self.minor = minor
        case 3:
            guard let major = versionComponents[0] else { return nil }
            guard let minor = versionComponents[1] else { return nil }
            guard let patch = versionComponents[2] else { return nil }
            self.major = major
            self.minor = minor
            self.patch = patch
        default: return nil
        }

        // Validate & initialize the pre-release and build
        // metadata identifiers.
        guard _validateIdentifiers(releaseComponents) else { return nil }
        self.preReleaseIdentifiers = releaseComponents
        guard _validateIdentifiers(buildComponents) else { return nil }
        self.buildMetadataIdentifiers = buildComponents
    }
}
public extension SemanticVersionable {
    /// Default implementation
    ///
    /// Default implementation returns an instance representing a semantic version number 0.0.0.
    var version:SemanticVersion {
        return SemanticVersion()
    }
    // Deprecated
    @available(*, deprecated, renamed: "version.description")
    var versionDescription:String { return version.description }
    /// API stability.
    ///
    /// Rule 4: Major version zero (0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT be considered stable.
    var isStable:Bool { return version.major != 0 && version.preReleaseIdentifiers == nil }
}
