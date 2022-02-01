import XCTest
#if os(Linux)
import Glibc
#endif

@testable import SemanticVersion

final class SemanticVersionTests: XCTestCase {
    struct V1_0_0 : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 0, 0) }
    }
    struct V1_0_0_aa : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 0, 0, ["a", "a"], nil)! }
    }
    struct V1_0_0_ab : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 0, 0, ["a", "b"], nil)! }
    }
    struct V1_0_1 : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 0, 1) }
    }
    class V1_1_0 : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 1, 0) }
    }
    struct V1_1_1 : SemanticVersionable {
        var version: SemanticVersion { return SemanticVersion(1, 1, 1) }
    }
    func test_00() {
        XCTAssertEqual(SemanticVersion(0, 0, 0, nil, nil)?.description, "0.0.0")
        XCTAssertEqual(SemanticVersion(UInt.max, UInt.max, UInt.max, nil, nil)?.description, "\(UInt.max).\(UInt.max).\(UInt.max)")
        XCTAssertEqual(SemanticVersion(0, 0, 0, [], nil)?.description, nil)
        XCTAssertEqual(SemanticVersion(0, 0, 0, [""], nil)?.description, nil)
        XCTAssertEqual(SemanticVersion(0, 0, 0, [""], [""])?.description, nil)
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a"], nil)?.description, "0.0.0-a")
        XCTAssertEqual(SemanticVersion(0, 0, 0, nil, ["a"])?.description, "0.0.0+a")
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a"], ["b"])?.description, "0.0.0-a+b")
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["-", "-"], ["-"])?.description, "0.0.0--.-+-")
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a", "b"], ["a", "b"])?.description, "0.0.0-a.b+a.b")
        XCTAssertEqual(SemanticVersion(0, 0, 0, nil, ["-"])?.description, "0.0.0+-")
        XCTAssertEqual(SemanticVersion(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])?.description, "1.0.0-beta.3+x86-64.debug")
        struct TestStruct : SemanticVersionable {
            var version: SemanticVersion {
                SemanticVersion(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])!
            }
        }
        struct TestClass : SemanticVersionable {
            var version: SemanticVersion {
                SemanticVersion(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])!
            }
        }
        XCTAssertNil(SemanticVersion(0, 0, 0, ["#"], ["%"])?.description)
        XCTAssertFalse(TestStruct().version.isStable)
        XCTAssertFalse(TestClass().version.isStable)
    }
    func test_comparators_1() {
        XCTAssertEqual(V1_0_0().version, V1_0_0().version)
        XCTAssertTrue(V1_0_0().version == V1_0_0().version)
        XCTAssertFalse((V1_0_0().version > V1_0_0().version))
        XCTAssertFalse((V1_0_0().version < V1_0_0().version))
        XCTAssertTrue((V1_0_0().version <= V1_0_0().version))
        XCTAssertTrue((V1_0_0().version >= V1_0_0().version))
        XCTAssertFalse((V1_0_0().version != V1_0_0().version))
    }
    func test_comparators_2() {
        XCTAssertFalse((V1_0_0().version == V1_0_1().version))
        XCTAssertTrue((V1_0_0().version < V1_0_1().version))
        XCTAssertFalse((V1_0_0().version > V1_0_1().version))
        XCTAssertTrue((V1_0_0().version <= V1_0_1().version))
        XCTAssertFalse((V1_0_0().version >= V1_0_1().version))
        XCTAssertTrue((V1_0_0().version != V1_0_1().version))
    }
    func test_comparators_3() {
        XCTAssert((V1_0_0().version == V1_1_1().version) == false)
        XCTAssert((V1_0_0().version < V1_1_1().version) == true)
        XCTAssert((V1_0_0().version > V1_1_1().version) == false)
        XCTAssertTrue((V1_0_0().version <= V1_1_1().version))
        XCTAssertFalse((V1_0_0().version >= V1_1_1().version))
        XCTAssertTrue((V1_0_0().version != V1_1_1().version))

        print(SemanticVersion(1, 0, 0, ["rc10"])! < SemanticVersion(1, 0, 0, ["rc9"])!)
        print(SemanticVersion(1, 0, 0, ["rc9"])! < SemanticVersion(1, 0, 0, ["rc10"])!)
        print(SemanticVersion(1, 0, 0, ["rc1"])! < SemanticVersion(1, 0, 0, ["rc10"])!)
        print(["rc10"].lexicographicallyPrecedes(["rc09"]))
        print(["rc9a"].lexicographicallyPrecedes(["rc09a"]))
        print(["10"].lexicographicallyPrecedes(["09"]))
    }
    func test_comparators_and_api_stability() {
        struct Foo : SemanticVersionable {
            var version: SemanticVersion { SemanticVersion() }
        }
        let foo = Foo()

        XCTAssertEqual(foo.version.description, "0.0.0")
        XCTAssertEqual(foo.version, SemanticVersion(0, 0, 0, nil, nil))
        XCTAssertFalse(foo.version.isStable)


        struct Bar : SemanticVersionable {
            var version: SemanticVersion {
                return SemanticVersion(1, 0, 0, nil, nil)!
            }
        }
        let bar = Bar()
        XCTAssertTrue(bar.version.isStable)
        XCTAssertEqual(bar.version.description, "1.0.0")


        struct Foobar : SemanticVersionable {
            var version: SemanticVersion {
                return SemanticVersion(1, 0, 0, ["pre-release", "dbg"], ["build", "76fc43d"])!
            }
        }
        let foobar = Foobar()
        XCTAssertFalse(foobar.version.isStable)
        XCTAssertEqual(foobar.version.description, "1.0.0-pre-release.dbg+build.76fc43d")
        XCTAssertTrue(foo.version < bar.version)
        XCTAssertTrue(foo.version < foobar.version)
        XCTAssertTrue(foobar.version == foobar.version)

        class Barfoo : NSObject, SemanticVersionable {
            var version: SemanticVersion { SemanticVersion() }
        }
        let barfoo = Barfoo()
        XCTAssertFalse(barfoo.version.isStable)
        XCTAssertEqual(barfoo.version.description, "0.0.0")
    }
    func test_filtering() {
        let baseLine = SemanticVersion(1,0,0)
        let modules = [
            SemanticVersion(0, 9, 99),
            SemanticVersion(1,2,3),
            baseLine,
            SemanticVersion(1, 0, 0, ["rc", "1"], ["debug"])!,
            SemanticVersion(1, 0, 0, ["rc", "1"])!,
            ]
        let baselineOrAbove = modules.filter({ $0 >= baseLine})
        XCTAssertTrue(baselineOrAbove.count == 2)
    }
    func test_ranges() {

        let v1 = SemanticVersion(1,0,0)
        let v2 = SemanticVersion(2,4,0)
        let v3 = SemanticVersion(3,2,1)
        let v4 = SemanticVersion(4,0,1)
        let v4pre = SemanticVersion(4,0,1,["rc1"])!
        do {
            let range = v2..<v4
            XCTAssert(range.contains(v1) == false)
            XCTAssert(range.contains(v2) == true)
            XCTAssert(range.contains(v3) == true)
            XCTAssert(range.contains(v4pre) == true)
            XCTAssert(range.contains(v4) == false)
        }
        do {
            let range = v2..<v4pre
            XCTAssert(range.contains(v1) == false)
            XCTAssert(range.contains(v2) == true)
            XCTAssert(range.contains(v3) == true)
            XCTAssert(range.contains(v4pre) == false)
            XCTAssert(range.contains(v4) == false)
        }
    }
    func test_init() {

        // SemanticVersion()
        do {
            let v = SemanticVersion()
            XCTAssertEqual(v.major, 0)
            XCTAssertEqual(v.minor, 0)
            XCTAssertEqual(v.patch, 0)
            XCTAssertEqual(v.preReleaseIdentifiers, nil)
            XCTAssertEqual(v.buildMetadataIdentifiers, nil)
        }

        // SemanticVersion(description: String)
        // -> test_LosslessStringConvertible

        // SemanticVersion(from: Decoder)
        // -> test_codable

        // SemanticVersion(major: UInt, minor: UInt, patch: UInt)
        // SemanticVersion(major: UInt, minor: UInt, patch: UInt, preReleaseIdentifiers: [String?])
        // SemanticVersion(major: UInt, minor: UInt, patch: UInt, preReleaseIdentifiers: [String?], buildMetadataIdentifiers:[String?])
        do {
            let v = SemanticVersion(major: 1, minor: 2, patch: 3)
            XCTAssertEqual(v.major, 1)
            XCTAssertEqual(v.minor, 2)
            XCTAssertEqual(v.patch, 3)
            XCTAssertEqual(v.preReleaseIdentifiers, nil)
            XCTAssertEqual(v.buildMetadataIdentifiers, nil)
        }
        do {
            let v = SemanticVersion(major: 1, minor: 2, patch: 3, preReleaseIdentifiers: ["a"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, nil)
        }
        do {
            let v = SemanticVersion(major: 1, minor: 2, patch: 3, preReleaseIdentifiers: ["a"], buildMetadataIdentifiers: ["b"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["b"])
        }
        // SemanticVersion(UInt, UInt, UInt)
        // SemanticVersion(UInt, UInt, UInt, [String?])
        // SemanticVersion(UInt, UInt, UInt, [String?], [String?])
        do {
            let v = SemanticVersion(1, 2, 3)
            XCTAssertEqual(v.major, 1)
            XCTAssertEqual(v.minor, 2)
            XCTAssertEqual(v.patch, 3)
            XCTAssertEqual(v.preReleaseIdentifiers, nil)
            XCTAssertEqual(v.buildMetadataIdentifiers, nil)
        }
        do {
            let v = SemanticVersion(1, 2, 3, ["a"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, nil)
        }
        do {
            let v = SemanticVersion(1, 2, 3, ["a"], ["b"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["b"])
        }
        do {
            let v = SemanticVersion(1, 2, 3, ["0"], ["0"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["0"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["0"])
        }
        do {
            // should fail as numeric identifiers must not include leading zeroes
            let v = SemanticVersion(1, 2, 3, ["00"])
            XCTAssertNil(v)
        }
        do {
            // should fail as numeric identifiers must not include leading zeroes
            let v = SemanticVersion(1, 2, 3, nil, ["00"])
            XCTAssertNil(v)
        }
        do {
            // should fail as numeric identifiers must not include leading zeroes
            let v = SemanticVersion(1, 2, 3, ["0a"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["0a"])
            XCTAssertNil(v?.buildMetadataIdentifiers)
        }
    }
    func test_codable() {
        let encoded:Data
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            encoded = try encoder.encode(V1_0_0_ab().version)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(SemanticVersion.self, from: encoded)
            XCTAssertTrue(decoded == V1_0_0_ab().version)
        }
        catch {
            XCTFail(error.localizedDescription)
        }

    }
    func testHashable() {
        let dict:[SemanticVersion:String] = [
            SemanticVersion(0,1,2): "a",
            SemanticVersion(3,4,5): "b"
        ]
        XCTAssertEqual(dict[SemanticVersion(0,1,2)], "a")
        XCTAssertEqual(dict[SemanticVersion(3,4,5)], "b")
    }
    func testEqualPrecedence() {
        XCTAssertTrue(SemanticVersion() == SemanticVersion())
        XCTAssertTrue(SemanticVersion() === SemanticVersion())

        XCTAssertTrue(SemanticVersion(1,2,3,nil,["a"]) == SemanticVersion(1,2,3,nil,["z"]))
        XCTAssertFalse(SemanticVersion(1,2,3,nil,["a"])! === SemanticVersion(1,2,3,nil,["z"])!)
        XCTAssertFalse(SemanticVersion(1,2,3,nil,["a"]) != SemanticVersion(1,2,3,nil,["z"]))
    }
    func test_LosslessStringConvertible() {
        let data:[(String, SemanticVersion?)] = [
            // Failing
            ("1.1.", nil),
            ("1..1", nil),
            ("1..", nil),
            (".1.1", nil),
            (".1.", nil),
            ("..1", nil),
            ("..1.1", nil),
            ("1.-alpha", nil),
            ("+", nil),
            ("-", nil),
            ("+-", nil),
            ("-+", nil),
            (".", nil),
            ("..", nil),
            ("...", nil),
            ("....", nil),
            ("1.2.3.4", nil),
            ("a", nil),
            ("------", nil),
            ("++++++", nil),
            ("1.2.3.", nil),
            ("1.2.3-a+b+c", nil),
            ("1++++++", nil),
            // Succeeding
            ("", SemanticVersion()),
            ("1", SemanticVersion(1,0,0)),
            ("1.2", SemanticVersion(1,2,0)),
            ("1.2.3", SemanticVersion(1,2,3)),
            ("1-alpha", SemanticVersion(1,0,0,["alpha"])),
            ("1.2-alpha", SemanticVersion(1,2,0,["alpha"])),
            ("1.2.3-alpha", SemanticVersion(1,2,3,["alpha"])),
            ("1-alpha+debug", SemanticVersion(1,0,0,["alpha"], ["debug"])),
            ("1.2-alpha+debug", SemanticVersion(1,2,0,["alpha"], ["debug"])),
            ("1.2.3-alpha+debug", SemanticVersion(1,2,3,["alpha"], ["debug"])),
            ("1+debug", SemanticVersion(1,0,0,nil, ["debug"])),
            ("1-pan-o-rama", SemanticVersion(1,0,0,["pan-o-rama"], nil)),
            ("1-pan-o-rama.2019", SemanticVersion(1,0,0,["pan-o-rama", "2019"], nil)),
            ("1.2+debug", SemanticVersion(1,2,0,nil, ["debug"])),
            ("1.2.3+debug", SemanticVersion(1,2,3,nil, ["debug"])),
            ("1.2.3-a+b", SemanticVersion(1,2,3,["a"], ["b"])),
            ("1.2.3-a.b.c", SemanticVersion(1,2,3,["a", "b", "c"], nil)),
            ("1------", SemanticVersion(1,0,0,["-----"], nil)), // Spec allows this!
        ]
        for (input,expected) in data {
            XCTAssertEqual(SemanticVersion(input), expected, "\(input) == \(String(describing: expected))")
        }
    }
    func test_semverRule_9_preRelease() {
        // A pre-release version MAY be denoted by appending a hyphen and
        // a series of dot separated identifiers immediately following the
        // patch version. Identifiers MUST comprise only ASCII alphanumerics
        // and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be empty. Numeric
        // identifiers MUST NOT include leading zeroes. Pre-release versions
        // have a lower precedence than the associated normal version.
        // A pre-release version indicates that the version is unstable and
        // might not satisfy the intended compatibility requirements as
        // denoted by its associated normal version.
        // Examples: 1.0.0-alpha, 1.0.0-alpha.1, 1.0.0-0.3.7, 1.0.0-x.7.z.92.
    }
    func test_semverRule_10_buildMetadata() {
        // Semver rule 10
        // Build metadata MAY be denoted by appending a plus sign and a series
        // of dot separated identifiers immediately following the patch or
        // pre-release version. Identifiers MUST comprise only ASCII
        // alphanumerics and hyphen [0-9A-Za-z-]. Identifiers MUST NOT be
        // empty. Build metadata MUST be ignored when determining version
        // precedence. Thus two versions that differ only in the build
        // metadata, have the same precedence.
        //
        // Examples:
        // 1.0.0-alpha+1
        // 1.0.0+20130313144700
        // 1.0.0-beta+exp.sha.5114f85

        let a = SemanticVersion(1, 0, 0, ["alpha"], ["1"])
        let b = SemanticVersion(1, 0, 0, ["alpha"], ["20130313144700"])
        let c = SemanticVersion(1, 0, 0, ["alpha"], ["exp", "sha", "5114f85"])

        for i in [a, b, c] {
            for j in [a, b, c] {
                XCTAssertTrue(i == j, "\(String(describing: i)) == \(String(describing: j))")
            }
        }
    }
    func test_semverRule_9_nonEmptyIdentifiers() {
        // Semver rules 9 & 10
        //
        // Identifiers MUST NOT be empty.

        XCTAssertEqual(SemanticVersion(0, 0, 0, [], nil)?.preReleaseIdentifiers, nil)
        XCTAssertEqual(SemanticVersion(0, 0, 0, [""], nil)?.preReleaseIdentifiers, nil)
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a", "", "b"], nil)?.preReleaseIdentifiers, nil)
    }
    func test_semverRule_9_asciiAlnumHyphen() {
        // Semver rules 9 & 10
        //
        // Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].

        // Single identifier containing all valid chars -> must pass
        let validChars = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-"
        XCTAssertNotNil(SemanticVersion(0, 0, 0, [validChars], nil))

        // Generate array of 5 identifiers from valid chars -> must pass
        var r = (0..<5).map { _ in (0..<5).reduce("", { (a,_) in return a + "\(validChars.randomElement()!)"; })}
        XCTAssertEqual(SemanticVersion(0, 0, 0, r, nil)?.preReleaseIdentifiers, r)

        // Weird, but allowed
        let tokens =  ["-", "-", "--", "-"]
        let v0 = SemanticVersion(0, 0, 0, tokens, nil)
        XCTAssertEqual(v0?.preReleaseIdentifiers, tokens)
        XCTAssertEqual(v0?.description, "0.0.0--.-.--.-")

        let valid = CharacterSet(charactersIn: validChars)
        var scalar:UnicodeScalar
        repeat {
            #if os(Linux)
            scalar = UnicodeScalar(unicodeScalarLiteral: "#")
            #else
            scalar = UnicodeScalar(arc4random()%255) ?? UnicodeScalar(unicodeScalarLiteral: "#")
            #endif
        } while valid.contains(scalar)
        // We should have a "nonvalid" scalar now
        XCTAssertFalse(valid.contains(scalar))
        // Create a token containing invalid character
        let invalidToken = r.first! + scalar.description + r.last!
        // Append invalid token to the end of valid tokens
        r.append(invalidToken)
        let v = SemanticVersion(0, 0, 0, r, nil)
        // Invalid token -> nil
        XCTAssertNil(v)
    }
    func test_semverRule_9_noLeadingZeroes() {
        // Semver rule 9
        //
        // Numeric identifiers MUST NOT include leading zeroes.
        // Note: It is not clear if above applies to Rule 10 as well (it is
        // not mentioned there)
        XCTAssertNil(SemanticVersion(0, 0, 0, ["01"], nil))
        XCTAssertNil(SemanticVersion(0, 0, 0, ["0001"], nil))
        XCTAssertNil(SemanticVersion(0, 0, 0, ["a","01","b"], nil))
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a","01rc","b"], nil), SemanticVersion(0, 0, 0, ["a", "01rc", "b"], nil))
        XCTAssertEqual(SemanticVersion(0, 0, 0, ["a","0"], nil)?.preReleaseIdentifiers, ["a", "0"])
        XCTAssertNil(SemanticVersion(0, 0, 0, ["a","00"], nil))
        XCTAssertNil(SemanticVersion(0, 0, 0, ["a","000"], nil))
    }
    func test_semverRule_11_precedence() {
        // Rule 11: a pre-release version has lower precedence
        // than a normal version
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["lower-precedence"])! < SemanticVersion(2, 3, 4))

        // Rule 11:
        // Precedence for two pre-release versions with the same major, minor,
        // and patch version MUST be determined by comparing each dot separated
        // identifier from left to right until a difference is found as follows:
        //
        // - identifiers consisting of only digits are compared numerically
        // - and identifiers with letters or hyphens are compared lexically in ASCII sort order.
        //
        // Numeric identifiers always have lower precedence
        // than non-numeric identifiers.
        //
        // A larger set of pre-release fields has a higher precedence than a
        // smaller set, if all of the preceding identifiers are equal. Exa

        // Compare numerically
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["0"])! < SemanticVersion(2, 3, 4, ["1"])!)
        // Compare lexically in ASCII sort order
        // "Z" appears before "z" in ASCII table
        // Hyphen (-) appears before "a" in ASCII table
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["Z"])! < SemanticVersion(2, 3, 4, ["z"])!)
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["-"])! < SemanticVersion(2, 3, 4, ["a"])!)
        // Unfortunately - lexical ASCII sort order means that "rc10" precedes "rc9"
        // A more natural sorting order for humans would be "rc9" < "rc10"
        // But as lexical sort order is the semver 2.0.0 spec, that must be followed then
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["rc10"])! < SemanticVersion(2, 3, 4, ["rc9"])!)

        // Numeric identifiers always have lower precedence than non-numeric identifiers.
        // Hyphen (-) appears before zero (0) in ASCII table
        XCTAssertTrue(SemanticVersion(2, 3, 4, ["0"])! < SemanticVersion(2, 3, 4, ["-"])!)

        // A larger set of pre-release fields has a higher precedence than a
        // smaller set, if all of the preceding identifiers are equal.
        let lower = SemanticVersion(2, 3, 4, ["0", "a"])!
        let higher = SemanticVersion(2, 3, 4, ["0", "a", "onemore"])!
        XCTAssertTrue(lower < higher)

        // Example
        do {
            let expectedSortingOrder = [
                SemanticVersion("1.0.0-alpha")!,
                SemanticVersion("1.0.0-alpha.1")!,
                SemanticVersion("1.0.0-alpha.beta")!,
                SemanticVersion("1.0.0-beta")!,
                SemanticVersion("1.0.0-beta.2")!,
                SemanticVersion("1.0.0-beta.11")!,
                SemanticVersion("1.0.0-rc.1")!,
                SemanticVersion("1.0.0")!
            ]
            _ = zip(expectedSortingOrder.dropLast(), expectedSortingOrder.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        #if SORT_OPTION_NONE
        do {
            let ordered = [
                SemanticVersion("1.0.0-alpha100")!,
                SemanticVersion("1.0.0-alpha20")!,
                SemanticVersion("1.0.0-alpha9")!,
                SemanticVersion("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        #else
        do {
            // Lexical ASCII sort order (unfortunately)
            let ordered = [
                SemanticVersion("1.0.0-alpha100")!,
                SemanticVersion("1.0.0-alpha20")!,
                SemanticVersion("1.0.0-alpha9")!,
                SemanticVersion("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        #endif
        do {
            let ordered = [
                SemanticVersion("1.0.0-alpha009")!,
                SemanticVersion("1.0.0-alpha020")!,
                SemanticVersion("1.0.0-alpha100")!,
                SemanticVersion("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        do {
            let ordered = [
                SemanticVersion("1.0.0-rc1")!,
                SemanticVersion("1.0.0-rc2")!,
                SemanticVersion("1.0.0-rc9")!, // Where do you go from here? 11?
                //SemanticVersion("1.0.0-rc10")!, // <- This would break your natural sort ordering
                SemanticVersion("1.0.0-rc9.0")!, // This saves the day - but is kind of an ugly hack
                SemanticVersion("1.0.0-rc9.9")!, // Now you already guess where you go from here...
                SemanticVersion("1.0.0-rc9.9.0")!, // Now you already guess where you go from here...
                SemanticVersion("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        do {
            let ordered = [
                SemanticVersion("1.0.0-are")!,
                SemanticVersion("1.0.0-hello")!,
                SemanticVersion("1.0.0-how")!,
                SemanticVersion("1.0.0-world")!,
                SemanticVersion("1.0.0-you")!,
                SemanticVersion("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
    }
    func test_sort() {
        func rnd() -> UInt {
            let r:ClosedRange<UInt> = (0...1)
            return r.randomElement() ?? 0
        }
        func rndstr() -> [String]? {
            if (0...1).randomElement() ?? 0 == 0 {
                return nil
            }
            else {
                let r = (0..<2).map { _ in (0..<1).reduce("", { (a,_) in return a + "\("abcdef".randomElement()!)"; })}
                return r
            }
        }
        var randomArray:[SemanticVersion] = []
        for _ in 0..<100 {
            let maj = rnd()
            let min = rnd()
            let bug = rnd()
            let rel = rndstr()
            let bld = rndstr()
            let version = "\(maj).\(min).\(bug)" + ((rel == nil) ? "" : "-" + (rel ?? []).joined(separator: ".")) + ((bld == nil) ? "" : "+" + (bld ?? []).joined(separator: "."))
            guard let semver = SemanticVersion(maj, min, bug, rel, bld) else {
                XCTFail()
                return
            }
            XCTAssertEqual(semver.description, version)
            randomArray.append(semver)
        }

        let sorted = randomArray.sorted()
        for (l,r) in zip(sorted.dropLast(), sorted.dropFirst()) {
            XCTAssertTrue(l <= r)
        }


        let input = [
            SemanticVersion(9,0,0,nil,nil),

            SemanticVersion(1,0,0,["rc","1"],nil),
            SemanticVersion(1,0,0,["1","1"],nil),
            SemanticVersion(1,0,0,["alpha", "1"],nil),
            SemanticVersion(1,0,0,["alpha","beta"], nil),
            SemanticVersion(1,0,0,["beta","2"],nil),
            SemanticVersion(1,0,0,["beta"],nil),
            SemanticVersion(1,0,0,["alpha"],nil),
            SemanticVersion(1,0,0,["beta","11"],nil),
            SemanticVersion(1,0,0,nil,nil),

            SemanticVersion(0,0,0,nil,nil),

        ]
        let expected = [
            SemanticVersion(0,0,0,nil,nil),

            SemanticVersion(1,0,0,["1","1"],nil),
            SemanticVersion(1,0,0,["alpha"],nil),
            SemanticVersion(1,0,0,["alpha", "1"],nil),
            SemanticVersion(1,0,0,["alpha","beta"], nil),
            SemanticVersion(1,0,0,["beta"],nil),
            SemanticVersion(1,0,0,["beta","2"],nil),
            SemanticVersion(1,0,0,["beta","11"],nil),
            SemanticVersion(1,0,0,["rc","1"],nil),
            SemanticVersion(1,0,0,nil,nil),

            SemanticVersion(9,0,0,nil,nil),
        ]
        _ = zip(input.compactMap({$0}).sorted(), expected).map {
            //print(String(describing: $0.0), "==", String(describing: $0.1))
            XCTAssertEqual($0.0, $0.1)
        }
    }
}
