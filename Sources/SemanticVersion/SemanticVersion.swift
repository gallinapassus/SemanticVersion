import Foundation


//
// https://semver.org
//
// MARK: -
/// A type that can represent a semantic version number.
///
/// Types that conform to SemanticVersionable can represent a version number as defined in semver 2.0.0 https://semver.org
public protocol SemanticVersionable : Sendable {
    var version:SemanticVersion { get }
}
// MARK: -
/// Concrete type representing a semantic version as defined in semver 2.0.0 https://semver.org
public struct SemanticVersion : Codable, Hashable, Equatable, Comparable, Sendable {

    // MARK: Public
    /// Major version number.
    ///
    /// Indicate backwards incompatible API changes by incrementing the major version.
    public var major:UInt = 0
    /// Minor version number.
    ///
    /// Indicate backwards compatible API additions/changes by incrementing the minor version.
    public var minor:UInt = 0
    /// Patch version number.
    ///
    /// Indicate bug fixes not affecting the API by incrementing the patch version.
    public var patch:UInt = 0
    /// Pre-release identifiers.
    ///
    /// A pre-release version can be denoted with pre-release identifiers.
    /// Pre-release version identifiers will follow immediately after the version number, separated with hyphen.
    /// Pre-release identifiers must contain only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Empty identifiers are not allowed and numeric identifiers must not include leading zeroes. Pre-release versions have a lower precedence than the associated normal version. A pre-release version indicates that the version is unstable and might not satisfy the intended compatibility requirements as denoted by its associated normal version.
    private(set) public var preReleaseIdentifiers:[String]?
    /// Build metadata identifiers.
    ///
    /// Build metadata can be denoted with metadata identifiers. Metadata identifiers will follow immediately the patch or pre-release version. Identifiers must contain only ASCII alphanumerics and hyphen [0-9A-Za-z-]. Empty identifiers are not allowed. Build metadata is ignored when determining version precedence. Thus two versions that differ only in the build metadata, have the same precedence.
    private(set) public var buildMetadataIdentifiers:[String]?
    /// Indicates API stability.
    public var isStable:Bool { return major != 0 && preReleaseIdentifiers == nil }

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
        // init will ignore tokens with invalid characters
        guard Self._validate(preReleaseIdentifiers, .prerelease) else { return nil }
        self.init(major, minor, patch)
        self.preReleaseIdentifiers = preReleaseIdentifiers
    }
    public init?(_ major: UInt, _ minor: UInt, _ patch: UInt,
                _ preReleaseIdentifiers: [String]?,
                _ buildMetadataIdentifiers: [String]?) {
        // init will ignore tokens with invalid characters
        guard Self._validate(preReleaseIdentifiers, .prerelease),
              Self._validate(buildMetadataIdentifiers, .buildmeta) else { return nil }
        self.init(major, minor, patch)
        self.preReleaseIdentifiers = preReleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }
    public init(major: UInt, minor: UInt, patch: UInt) {
        self.init(major, minor, patch)
    }
    public init?(major: UInt, minor: UInt, patch: UInt, preReleaseIdentifiers: [String]?) {
        // init will ignore tokens with invalid characters
        guard Self._validate(preReleaseIdentifiers, .prerelease) else { return nil }
        self.init(major, minor, patch)
        self.preReleaseIdentifiers = preReleaseIdentifiers
    }
    public init?(major: UInt, minor: UInt, patch: UInt,
                preReleaseIdentifiers: [String]?,
                buildMetadataIdentifiers: [String]?) {
        // init will ignore tokens with invalid characters
        guard Self._validate(preReleaseIdentifiers, .prerelease),
              Self._validate(buildMetadataIdentifiers, .buildmeta) else { return nil }
        self.init(major, minor, patch)
        self.preReleaseIdentifiers = preReleaseIdentifiers
        self.buildMetadataIdentifiers = buildMetadataIdentifiers
    }
    // MARK: -
    // MARK: Comparable, Equatable
    /// Compare version number equality by their precedence
    ///
    /// Please note that this operator compares version number predence rather than exact instance variable equality. In semantic versioning, metadata identifiers have no effect in determining the precedence. Thus, two version numbers can be precedence-vice equal, while they differ in their instance variables.
    ///
    /// Use `===` if you need to find out if two instances are equal by their instance variables.
    ///
    /// Example: Precedence comparisons
    ///
    /// ```
    /// SemanticVersion() == SemanticVersion() // true
    /// SemanticVersion(1,2,3,nil,["a"]) == SemanticVersion(1,2,3,nil,["z"]) // true
    /// SemanticVersion(1,2,3,nil,["a"]) === SemanticVersion(1,2,3,nil,["z"]) // false
    /// SemanticVersion(1,2,3,nil,["a"]) != SemanticVersion(1,2,3,nil,["z"]) // false
    /// ```

    public static func ==(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return (lhs < rhs) == false && (lhs > rhs) == false
    }
    /// Compare version number instance variable equality.
    ///
    /// Important: See also ``==(_:_:)``

    public static func ===(lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        return lhs.major == rhs.major &&
        lhs.minor == rhs.minor &&
        lhs.patch == rhs.patch &&
        lhs.preReleaseIdentifiers == rhs.preReleaseIdentifiers &&
        lhs.buildMetadataIdentifiers == rhs.buildMetadataIdentifiers
    }
    /// Compare version number precedence
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major < rhs.major {
            return true
        }
        else if lhs.major > rhs.major {
            return false
        }
        else if lhs.major == rhs.major {
            // Next level
            if lhs.minor < rhs.minor {
                return true
            }
            else if lhs.minor > rhs.minor {
                return false
            }
            else if lhs.minor == rhs.minor {
                // Next level
                if lhs.patch < rhs.patch {
                    return true
                }
                else if lhs.patch > rhs.patch {
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
                let r = Self._tokenCompare(lhsTokens, rhsTokens, .prerelease)
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
    // MARK: -
    // MARK: Internal
    private enum IdentifierType { case prerelease, buildmeta }
    private static func _validate(_ identifiers:[String]?, _ type:IdentifierType) -> Bool {
        // identifiers == nil -> ok
        guard let identifiers = identifiers else {
            return true
        }
        // An empty array is ok as it doesn't contain empty identifiers
        guard identifiers.isEmpty == false else {
            return true // Empty array -> ok
        }
        // - Don't allow empty identifiers inside [""]
        guard identifiers.allSatisfy({ $0.isEmpty == false }) else {
            // At least one of the identifiers was empty -> not valid
            return false
        }
        // - Require identifiers to be either valid numeric identifiers
        //   or valid alphanumeric or hyphen identifiers [0-9A-Za-z-]
        //
        // NOTE: String "0123" is valid alphanumeric identifier, but
        // as it contains only numbers, it will be treated as numeric
        // identifier. And and as it has a leading zero, it becomes
        // a non-valid identifier.

        return identifiers.allSatisfy({ (s) in
            guard Self._isValidNumericToken(s, type) == true else {
                // not a "pure" numeric identifier
                // is it [0-9A-Za-z-] identifier?
                return Self._isAlphaNumericOrHyphenToken(s) && // [0-9A-Za-z-]
                    _isNumericToken(s) == false // pure numeric identifiers are no longer accepted
            }
            return true // Was valid numeric identifier
        })
    }

    private static func _isAlphaNumericOrHyphenToken(_ token:String) -> Bool {
        return !token.isEmpty &&
            CharacterSet(charactersIn: token)
            .isSubset(of: _validIdentifierChars)
    }

    private static func _isValidNumericToken(_ token:String, _ type: IdentifierType) -> Bool {
        // Only numbers allowed
        // No leading zeroes allowed in prerelease numeric identifiers
        // Leading zeroes are allowed in buildmeta numeric identifiers


        guard Self._isNumericToken(token) else {
            return false
        }
        // Extract all zeros from the beginning
        let leadingZeroes = token.prefix(while: { (char) -> Bool in char == "0" })
        // One zero "0" is ok, two or more zeros "00", means we have leading zeros -> not ok
        if leadingZeroes.count >= 1 && token.count > 1 && type == .prerelease {
            return false
        }
        // Finally, check that the "numeric string" can be converted to UInt
        guard UInt(token) != nil else {
            return false
        }
        // Do not allow empty identifiers
        return !token.isEmpty
    }
    private static func _isNumericToken(_ token:String) -> Bool {
        return CharacterSet(charactersIn: token)
            .isSubset(of: CharacterSet(charactersIn: "1234567890"))
    }
    private static func _tokenCompare(_ lhs:[String], _ rhs:[String], _ type:IdentifierType) -> Bool {

        for (l,r) in zip(lhs, rhs) {
            switch (_isValidNumericToken(l, type), _isValidNumericToken(r, type)) {
            case (true, true):
                guard let ul = UInt(l), let ur = UInt(r) else {
                    // This should never happen, but if it does, let's compare
                    // numeric tokens as strings
                    if l == r { continue }
                    else {
                        if l.count == r.count {
                            // equal character count, hence string comparison
                            // returns correct result
                            return l < r
                        }
                        else {
                            // different character count, shorter string is smaller
                            return l.count < r.count
                        }
                    }
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
                //
                // 2022: Reverting the above decision in order to fully comply
                // with the semver 2.0.0 spec

                // Following line enables strict conformance to semver 2.0.0
                let sortOptions:NSString.CompareOptions = []
                // Following line enables a more "natural" sort order for humans
                // let sortOptions:NSString.CompareOptions = [.numeric]

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
}
// MARK: -
// MARK: _validIdentifierChars
/// Valid characters for pre-release and build metadata identifiers
///
/// ASCII letters `[0-9A-Za-z-]`
fileprivate let _validIdentifierChars = CharacterSet(charactersIn: "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-")
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
        //       ^- is cut from here
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
        guard Self._validate(releaseComponents, .prerelease),
              Self._validate(buildComponents, .buildmeta) else { return nil }
        self.preReleaseIdentifiers = releaseComponents
        self.buildMetadataIdentifiers = buildComponents
    }
}
