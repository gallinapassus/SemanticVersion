import XCTest
#if os(Linux)
import Glibc
#endif

@testable import SemanticVersion

final class SemanticVersionTests: XCTestCase {
    typealias V = SemanticVersion
    func test_description() {
        XCTAssertEqual(V(0, 0, 0, nil, nil)?.description, "0.0.0")
        XCTAssertEqual(V(UInt.max, UInt.max, UInt.max, nil, nil)?.description, "\(UInt.max).\(UInt.max).\(UInt.max)")
        XCTAssertEqual(V(0, 0, 0, [], nil)?.description, "0.0.0")
        XCTAssertEqual(V(0, 0, 0, [""], nil)?.description, nil)
        XCTAssertEqual(V(0, 0, 0, [""], [""])?.description, nil)
        XCTAssertEqual(V(0, 0, 0, ["a"], nil)?.description, "0.0.0-a")
        XCTAssertEqual(V(0, 0, 0, nil, ["a"])?.description, "0.0.0+a")
        XCTAssertEqual(V(0, 0, 0, ["a"], ["b"])?.description, "0.0.0-a+b")
        XCTAssertEqual(V(0, 0, 0, ["-", "-"], ["-"])?.description, "0.0.0--.-+-")
        XCTAssertEqual(V(0, 0, 0, ["a", "b"], ["a", "b"])?.description, "0.0.0-a.b+a.b")
        XCTAssertEqual(V(0, 0, 0, nil, ["-"])?.description, "0.0.0+-")
        XCTAssertEqual(V(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])?.description, "1.0.0-beta.3+x86-64.debug")
        struct TestStruct : SemanticVersionable {
            var version: SemanticVersion {
                V(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])!
            }
        }
        struct TestClass : SemanticVersionable {
            var version: SemanticVersion {
                V(1, 0, 0, ["beta", "3"], ["x86-64", "debug"])!
            }
        }
        XCTAssertFalse(TestStruct().version.isStable)
        XCTAssertFalse(TestClass().version.isStable)
        XCTAssertEqual(TestStruct().version.description, "1.0.0-beta.3+x86-64.debug")
        XCTAssertEqual(TestClass().version.description, "1.0.0-beta.3+x86-64.debug")
    }
    func test_comparators_and_api_stability() {
        struct Foo : SemanticVersionable {
            var version: SemanticVersion { V() }
        }
        let foo = Foo()

        XCTAssertEqual(foo.version.description, "0.0.0")
        XCTAssertEqual(foo.version, V(0, 0, 0, nil, nil))
        XCTAssertFalse(foo.version.isStable)


        struct Bar : SemanticVersionable {
            var version: SemanticVersion {
                return V(1, 0, 0, nil, nil)!
            }
        }
        let bar = Bar()
        XCTAssertTrue(bar.version.isStable)
        XCTAssertEqual(bar.version.description, "1.0.0")


        struct Foobar : SemanticVersionable {
            var version: SemanticVersion {
                return V(1, 0, 0, ["pre-release", "dbg"], ["build", "76fc43d"])!
            }
        }
        let foobar = Foobar()
        XCTAssertFalse(foobar.version.isStable)
        XCTAssertEqual(foobar.version.description, "1.0.0-pre-release.dbg+build.76fc43d")
        XCTAssertTrue(foo.version < bar.version)
        XCTAssertTrue(foo.version < foobar.version)
        XCTAssertTrue(foobar.version == foobar.version)

        class Barfoo : NSObject, SemanticVersionable {
            var version: SemanticVersion { V() }
        }
        let barfoo = Barfoo()
        XCTAssertFalse(barfoo.version.isStable)
        XCTAssertEqual(barfoo.version.description, "0.0.0")
    }
    func test_precedence() {
        // Precedence refers to how versions are compared to each other when
        // ordered.
        //
        // Precedence MUST be calculated by separating the version into major,
        // minor, patch and pre-release identifiers in that order (Build
        // metadata does not figure into precedence).
        //
        // Precedence is determined by the first difference when comparing each
        // of these identifiers from left to right as follows: Major, minor, and
        // patch versions are always compared numerically.
        //
        // Example: 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1.
        //
        // When major, minor, and patch are equal, a pre-release version has
        // lower precedence than a normal version:
        //
        // Example: 1.0.0-alpha < 1.0.0.
        //
        // Precedence for two pre-release versions with the same major, minor,
        // and patch version MUST be determined by comparing each dot separated
        // identifier from left to right until a difference is found as follows:
        //
        // Identifiers consisting of only digits are compared numerically.
        //
        // Identifiers with letters or hyphens are compared lexically in ASCII
        // sort order.
        //
        // Numeric identifiers always have lower precedence than non-numeric
        // identifiers.
        //
        // A larger set of pre-release fields has a higher precedence than a
        // smaller set, if all of the preceding identifiers are equal.
        //
        // Example: 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta
        // < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
        //
        // Prerelease identifiers are taken into account when determining
        // precedence
        //
        // Metadata identifiers are ignored when determining precedence
        //
        // Pre-release versions have a lower precedence than the associated
        // normal version. A pre-release version indicates that the version is
        // unstable and might not satisfy the intended compatibility
        // requirements as denoted by its associated normal version.

        // <
        XCTAssertFalse(V(0, 0, 0) < V(0, 0, 0))
        XCTAssertTrue(V(0, 0, 0) < V(0, 0, 1))
        XCTAssertFalse(V(0, 1, 0) < V(0, 1, 0))
        XCTAssertTrue(V(0, 1, 0) < V(0, 1, 1))
        XCTAssertFalse(V(1, 0, 0) < V(1, 0, 0))
        XCTAssertTrue(V(1, 0, 0) < V(1, 0, 1))
        XCTAssertTrue(V(1, 0, 0) < V(1, 1, 0))
        XCTAssertTrue(V(1, 0, 0, ["alpha"])! < V(1, 0, 0))
        XCTAssertTrue(V(1, 0, 0, ["alpha", "1"])! < V(1, 0, 0))
        XCTAssertTrue(V(1, 0, 0, ["0", "3", "7"])! < V(1, 0, 0))
        XCTAssertTrue(V(1, 0, 0, ["x-y-z", "-"])! < V(1, 0, 0))
        XCTAssertTrue(V(1, 0, 0, ["a"])! < V(1, 0, 0, ["b"])!)
        XCTAssertFalse(V(1, 0, 0, ["a"])! < V(1, 0, 0, ["a"])!)
        XCTAssertTrue(V(1, 0, 0, ["a"])! < V(1, 0, 0, ["a", "b"])!)
        // "-" < "0", but as the rules state, numeric identifiers always have
        // lower precedence than non-numeric identifiers.
        XCTAssertTrue(V(1, 0, 0, ["a", "0"])! < V(1, 0, 0, ["a", "-"])!)
        // "0a" and "Z" are to be compared lexically and
        // "0a".lexicographicallyPrecedes("Z")
        XCTAssertTrue(V(1, 0, 0, ["a", "0a"])! < V(1, 0, 0, ["a", "Z"])!)
        // "Z".lexicographicallyPrecedes("z")
        XCTAssertTrue(V(1, 0, 0, ["a", "ZZ"])! < V(1, 0, 0, ["a", "zZ"])!)
        // Metadata identifiers are ignored when determining precedence
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! < V(1, 0, 0, nil, ["a"])!)
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! < V(1, 0, 0, nil, ["b"])!)
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! < V(1, 0, 0, nil, ["a", "b"])!)
        // <=
        // >
        XCTAssertFalse(V(0, 0, 0) > V(0, 0, 0))
        XCTAssertFalse(V(0, 0, 0) > V(0, 0, 1))
        XCTAssertFalse(V(0, 1, 0) > V(0, 1, 0))
        XCTAssertFalse(V(0, 1, 0) > V(0, 1, 1))
        XCTAssertFalse(V(1, 0, 0) > V(1, 0, 0))
        XCTAssertFalse(V(1, 0, 0) > V(1, 0, 1))
        XCTAssertFalse(V(1, 0, 0) > V(1, 1, 0))
        XCTAssertFalse(V(1, 0, 0, ["alpha"])! > V(1, 0, 0))
        XCTAssertFalse(V(1, 0, 0, ["alpha", "1"])! > V(1, 0, 0))
        XCTAssertFalse(V(1, 0, 0, ["0", "3", "7"])! > V(1, 0, 0))
        XCTAssertFalse(V(1, 0, 0, ["x-y-z", "-"])! > V(1, 0, 0))
        XCTAssertFalse(V(1, 0, 0, ["a"])! > V(1, 0, 0, ["b"])!)
        XCTAssertFalse(V(1, 0, 0, ["a"])! > V(1, 0, 0, ["a"])!)
        XCTAssertFalse(V(1, 0, 0, ["a"])! > V(1, 0, 0, ["a", "b"])!)
        // "-" < "0", but as the rules state, numeric identifiers always have
        // lower precedence than non-numeric identifiers.
        XCTAssertFalse(V(1, 0, 0, ["a", "0"])! > V(1, 0, 0, ["a", "-"])!)
        // "0a" and "Z" are to be compared lexically and
        // "0a".lexicographicallyPrecedes("Z")
        XCTAssertFalse(V(1, 0, 0, ["a", "0a"])! > V(1, 0, 0, ["a", "Z"])!)
        // "Z".lexicographicallyPrecedes("z")
        XCTAssertFalse(V(1, 0, 0, ["a", "ZZ"])! > V(1, 0, 0, ["a", "zZ"])!)
        // Metadata identifiers are ignored when determining precedence
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! > V(1, 0, 0, nil, ["a"])!)
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! > V(1, 0, 0, nil, ["b"])!)
        XCTAssertFalse(V(1, 0, 0, nil, ["a"])! > V(1, 0, 0, nil, ["a", "b"])!)
        // >=
        XCTAssertTrue(V() >= V())
        XCTAssertTrue(V(1, 2, 3) >= V(1, 2, 3))
        XCTAssertTrue(V(1, 2, 3) >= V(1, 2, 3, ["a"])!)
        XCTAssertTrue(V(1, 2, 3) >= V(1, 2, 3, nil, ["a"])!)
        XCTAssertTrue(V(1, 2, 3, nil, ["a"])! >= V(1, 2, 3, nil, ["b"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"])! >= V(1, 2, 3, ["a"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"], ["x"])! >= V(1, 2, 3, ["a"], ["y"])!)
        // ==
        XCTAssertTrue(V() == V())
        XCTAssertTrue(V(1, 2, 3) == V(1, 2, 3))
        XCTAssertFalse(V(1, 2, 3) == V(1, 2, 3, ["a"]))
        XCTAssertTrue(V(1, 2, 3) == V(1, 2, 3, nil, ["a"]))
        XCTAssertTrue(V(1, 2, 3, nil, ["a"])! == V(1, 2, 3, nil, ["b"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"])! == V(1, 2, 3, ["a"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"], ["x"])! == V(1, 2, 3, ["a"], ["y"])!)
        // !=
        XCTAssertTrue(V(1,2,3) != V(1,2,4))
        XCTAssertTrue(V(1,2,3) != V(1,3,3))
        XCTAssertTrue(V(1,2,3) != V(2,2,3))
        XCTAssertTrue(V(1, 2, 3) != V(1, 2, 3, ["b"])!)
        XCTAssertFalse(V(1, 2, 3) != V(1, 2, 3, nil, ["b"])!)
        XCTAssertFalse(V(1, 2, 3, nil, ["a"]) != V(1, 2, 3, nil, ["b"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"])! != V(1, 2, 3, ["b"])!)
        XCTAssertTrue(V(1, 2, 3, ["a", "b"])! != V(1, 2, 3, ["a"])!)
        XCTAssertTrue(V(1, 2, 3, ["a"], ["x"])! != V(1, 2, 3, ["b"], ["y"])!)
        XCTAssertFalse(V(1, 2, 3, ["a"], ["x"])! != V(1, 2, 3, ["a"], ["y"])!)
    }
    func test_instanceEquality() {
        // ===
        let x = V(1, 2, 3)
        let y = V(1, 2, 3, ["y"])!
        let z = V(1, 2, 3, nil, ["z"])!
        XCTAssertTrue(x === x)
        XCTAssertTrue(y === y)
        XCTAssertTrue(z === z)
    }
    func test_ranges() {

        let v1 = V(1,0,0)
        let v2 = V(2,4,0)
        let v3 = V(3,2,1)
        let v4 = V(4,0,1)
        let v4pre = V(4,0,1,["rc1"])!
        let v5 = V(5, 0, 0)
        let v5pre = V(5, 0, 0, ["rc"])!
        let v5meta = V(5, 0, 0, nil, ["arm64"])!
        let v5premeta = V(5, 0, 0, ["rc"], ["arm64", "debug"])!
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
        do {
            let range = v1...v5
            XCTAssertTrue(range.contains(v5meta))
            XCTAssertTrue(range.contains(v5pre))
            XCTAssertTrue(range.contains(v5premeta))
        }
    }
    func test_init() {

        // SemanticVersion()
        do {
            let v = V()
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
            let v = V(major: 1, minor: 2, patch: 3)
            XCTAssertEqual(v.major, 1)
            XCTAssertEqual(v.minor, 2)
            XCTAssertEqual(v.patch, 3)
            XCTAssertEqual(v.preReleaseIdentifiers, nil)
            XCTAssertEqual(v.buildMetadataIdentifiers, nil)
        }
        do {
            let v = V(major: 1, minor: 2, patch: 3,
                      preReleaseIdentifiers: ["a"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, nil)
        }
        do {
            let v = V(major: 1, minor: 2, patch: 3,
                      preReleaseIdentifiers: ["a"],
                      buildMetadataIdentifiers: ["b"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["b"])
        }
        do {
            let v = V(major: 1, minor: 2, patch: 3,
                      preReleaseIdentifiers: nil,
                      buildMetadataIdentifiers: ["b"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, nil)
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["b"])
        }
        // SemanticVersion(UInt, UInt, UInt)
        // SemanticVersion(UInt, UInt, UInt, [String?])
        // SemanticVersion(UInt, UInt, UInt, [String?], [String?])
        do {
            let v = V(1, 2, 3)
            XCTAssertEqual(v.major, 1)
            XCTAssertEqual(v.minor, 2)
            XCTAssertEqual(v.patch, 3)
            XCTAssertEqual(v.preReleaseIdentifiers, nil)
            XCTAssertEqual(v.buildMetadataIdentifiers, nil)
        }
        do {
            let v = V(1, 2, 3, ["a"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, nil)
        }
        do {
            let v = V(1, 2, 3, ["a"], ["b"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["a"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["b"])
        }
        do {
            let v = V(1, 2, 3, ["0"], ["0"])
            XCTAssertEqual(v?.major, 1)
            XCTAssertEqual(v?.minor, 2)
            XCTAssertEqual(v?.patch, 3)
            XCTAssertEqual(v?.preReleaseIdentifiers, ["0"])
            XCTAssertEqual(v?.buildMetadataIdentifiers, ["0"])
        }
        do {
            // should fail as pre-release numeric identifiers must not include
            // leading zeroes
            let v = V(1, 2, 3, ["00"])
            XCTAssertNil(v)
        }
        do {
            // should not fail as metadata numeric identifiers may include
            // leading zeroes
            let v = V(1, 2, 3, nil, ["00"])
            XCTAssertNotNil(v)
        }
    }
    func test_codable() {
        let encoded:Data
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let v = V(1,2,3,["rc", "3"], ["debug"])!
            encoded = try encoder.encode(v)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(SemanticVersion.self, from: encoded)
            XCTAssertTrue(decoded === v)
        }
        catch {
            XCTFail(error.localizedDescription)
        }

    }
    func testHashable() {
        let dict:[SemanticVersion:String] = [
            V(0,1,2): "a",
            V(3,4,5): "b"
        ]
        XCTAssertEqual(dict[V(0,1,2)], "a")
        XCTAssertEqual(dict[V(3,4,5)], "b")
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
    func test_nonEmptyIdentifiers() {
        // Identifiers MUST NOT be empty.

        // Empty array ok as it doesn't contain empty identifier
        XCTAssertNotNil(V(1,0,0, []))
        XCTAssertNotNil(V(1,0,0, nil, []))
        // Empty identifiers are not allowed
        XCTAssertNil(V(1,0,0, [""]))
        XCTAssertNil(V(1,0,0, nil, [""]))
        
        XCTAssertNil(V(0, 0, 0, ["a", "", "b"], nil))
        XCTAssertNil(V(0, 0, 0, nil, ["a", "", "b"]))
        XCTAssertNil(V(0, 0, 0, ["a", "", "b"], ["a", "", "b"]))

        XCTAssertEqual(V(0, 0, 0, [], nil)!.preReleaseIdentifiers, [])
        XCTAssertEqual(V(0, 0, 0, nil, [])!.buildMetadataIdentifiers, [])
        let v = V(1, 2, 3, [], [])!
        XCTAssertEqual(v.major, 1)
        XCTAssertEqual(v.minor, 2)
        XCTAssertEqual(v.patch, 3)
        XCTAssertEqual(v.preReleaseIdentifiers, [])
        XCTAssertEqual(v.buildMetadataIdentifiers, [])
    }
    func test_asciiAlnumHyphen() {
        // Identifiers MUST comprise only ASCII alphanumerics and hyphen [0-9A-Za-z-].

        // Single identifier containing all valid chars -> must pass
        let validChars = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-"
        XCTAssertNotNil(V(0, 0, 0, [validChars], nil))

        // Generate array of 5 identifiers from valid chars -> must pass
        var r = (0..<5).map { _ in (0..<5).reduce("", { (a,_) in return a + "\(validChars.randomElement()!)"; })}
        XCTAssertEqual(V(0, 0, 0, r, nil)?.preReleaseIdentifiers, r)

        // Weird, but allowed
        let tokens =  ["-", "-", "--", "-"]
        let v0 = V(0, 0, 0, tokens, nil)!
        XCTAssertEqual(v0.preReleaseIdentifiers, tokens)
        XCTAssertEqual(v0.description, "0.0.0--.-.--.-")

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
    func test_noLeadingZeroes() {
        // Numeric identifiers MUST NOT include leading zeroes.
        // Note: It is not clear if above applies to Rule 10 as well (it is
        // not mentioned there)
        XCTAssertNil(V(0, 0, 0, ["01"], nil))
        XCTAssertNil(V(0, 0, 0, ["0001"], nil))
        XCTAssertNil(V(0, 0, 0, ["a","01","b"], nil))
        XCTAssertNotNil(V(0, 0, 0, ["a","01rc","b"], nil))
        XCTAssertEqual(V(0, 0, 0, ["a","0"], nil)!.preReleaseIdentifiers, ["a", "0"])
        XCTAssertNil(V(0, 0, 0, ["a","00"], nil))
        XCTAssertNil(V(0, 0, 0, ["a","000"], nil))
    }
    func test_allowLeadingZeroes() {
        // Build metadata identifiers may contain numeric identifiers with
        // leading zeros
//        XCTAssertNotNil(V(0, 0, 0, nil, ["a","0"]))
        XCTAssertNotNil(V(0, 0, 0, nil, ["a","00"]))
//        XCTAssertNotNil(V(0, 0, 0, nil, ["a","000"]))
    }
    func test_semverRule_11_precedence() {

        // Example
        do {
            let expectedSortingOrder = [
                V("1.0.0-alpha")!,
                V("1.0.0-alpha.1")!,
                V("1.0.0-alpha.beta")!,
                V("1.0.0-beta")!,
                V("1.0.0-beta.2")!,
                V("1.0.0-beta.11")!,
                V("1.0.0-rc.1")!,
                V("1.0.0")!
            ]
            _ = zip(expectedSortingOrder.dropLast(), expectedSortingOrder.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        do {
            let ordered = [
                V("1.0.0-alpha009")!,
                V("1.0.0-alpha020")!,
                V("1.0.0-alpha100")!,
                V("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        do {
            let ordered = [
                V("1.0.0-rc1")!,
                V("1.0.0-rc2")!,
                V("1.0.0-rc9")!, // Where do you go from here? 11?
                //V("1.0.0-rc10")!, // <- This would break your natural sort ordering
                V("1.0.0-rc9.0")!, // This saves the day - but is kind of an ugly hack
                V("1.0.0-rc9.9")!, // Now you already guess where you go from here...
                V("1.0.0-rc9.9.0")!, // Now you already guess where you go from here...
                V("1.0.0")!
            ]
            _ = zip(ordered.dropLast(), ordered.dropFirst()).map {
                XCTAssertTrue($0.0 < $0.1, "\($0.0) < \($0.1)")
            }
        }
        do {
            let ordered = [
                V("1.0.0-are")!,
                V("1.0.0-hello")!,
                V("1.0.0-how")!,
                V("1.0.0-world")!,
                V("1.0.0-you")!,
                V("1.0.0")!
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
            guard let semver = V(maj, min, bug, rel, bld) else {
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
            V(9,0,0,nil,nil),

            V(1,0,0,["rc","1"],nil),
            V(1,0,0,["1","1"],nil),
            V(1,0,0,["alpha", "1"],nil),
            V(1,0,0,["alpha","beta"], nil),
            V(1,0,0,["beta","2"],nil),
            V(1,0,0,["beta"],nil),
            V(1,0,0,["alpha"],nil),
            V(1,0,0,["beta","11"],nil),
            V(1,0,0,nil,nil),

            V(0,0,0,nil,nil),

        ]
        let expected = [
            V(0,0,0,nil,nil),

            V(1,0,0,["1","1"],nil),
            V(1,0,0,["alpha"],nil),
            V(1,0,0,["alpha", "1"],nil),
            V(1,0,0,["alpha","beta"], nil),
            V(1,0,0,["beta"],nil),
            V(1,0,0,["beta","2"],nil),
            V(1,0,0,["beta","11"],nil),
            V(1,0,0,["rc","1"],nil),
            V(1,0,0,nil,nil),

            V(9,0,0,nil,nil),
        ]
        _ = zip(input.compactMap({$0}).sorted(), expected).map {
            //print(String(describing: $0.0), "==", String(describing: $0.1))
            XCTAssertEqual($0.0, $0.1)
        }
    }
}
