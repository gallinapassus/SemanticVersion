# SemanticVersion

Easy semantic versioning for your apps and code. SemanticVersion defines a `SemanticVersionable` protocol and a concrete type `SemanticVersion` capable of representing sematic version numbers.

More info about semantic versioning: https://semver.org

This implementation follows rules defined in semver 2.0.0

## Protocol

    public protocol SemanticVersionable {
        var version:SemanticVersion { get }
    }

Protocol includes default implementation for the `version`. Usefulness of the default implementation can be debated.

Example: Make struct/class versionable through default implementation

    struct Foo : SemanticVersionable {
    ...
    }
    
    Foo().version.description // default implementation returns 0.0.0

## Implementing the protocol

Implementing `SemanticVersionable` protocol is easy - just include `version` variable returning `SemanticVersion` instance.

    struct Bar : SemanticVersionable {
        ...
        var version: SemanticVersion {
            return SemanticVersion(major: 1, minor: 0, patch: 0, preReleaseIdentifiers: nil, buildMetadataIdentifiers: nil)
        }
    }
    Bar().versionDescription // "1.0.0"

## Comparing versions

SemanticVersion instances are `Comparable` and `Equatable`, hence comparing versions is possible.

    Foo().version < Bar().version // "true"
    var modules:[SemanticVersionable] = [Foo(), Bar()]
    modules.filter { $0.version >= SemanticVersion("1.0.0")! } // [Bar()]
    
## Determine API stability

Determining API stability is easy:

    Foo().isStable // false
    Bar().isStable // true

See semantic versioning api stability definition https://semver.org

## Example

    @NSApplicationMain
    public class MyApp: NSObject, NSApplicationDelegate {
    ...
    }

    extension NSApplication : SemanticVersionable {
        public var version: SemanticVersion {
            var preReleaseIdentifiers:[String]? = nil // ["alpha"] ... ["beta"] ... ["rc1"]
            var buildMetadataIdentifiers:[String]? = nil
            #if DEBUG
            buildMetadataIdentifiers = ["debug"]
            if let delegate = NSApp.delegate {
                buildMetadataIdentifiers?.insert("\(type(of:delegate))", at: 0)
            }
            #else
            if let delegate = NSApp.delegate {
                buildMetadataIdentifiers = ["\(type(of:delegate))"]
            }
            #endif
            return SemanticVersion(major: 1, minor: 0, bugfix: 1,
                                   preReleaseIdentifiers: preReleaseIdentifiers,
                                   buildMetadataIdentifiers: buildMetadataIdentifiers)
        }
    }

Then, anywhere in the application, you can write

    NSApp.version.description
    
And depending on your build configuration you will get

    "1.0.1+MyApp" -or- "1.0.1+MyApp.debug"
