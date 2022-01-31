# ``SemanticVersion``
Concrete type representing a semantic version as defined in semver 2.0.0 https://semver.org
<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->
## Overview

SemanticVersion defines a concrete type `SemanticVersion` capable of representing a semantic version number. It also defines a `SemanticVersionable` protocol for classes/structs wanting to declare conformance to semantic versioning.

## Example

Make struct/class versionable

    extension MyApp : SemanticVersionable {
        var version: SemanticVersion {
            return SemanticVersion(major: 1, minor: 0, patch: 0,
                                   preReleaseIdentifiers: ["beta", "3"],
                                   buildMetadataIdentifiers: ["x86-64", "debug"])!
        }
    }
    MyApp().version.description // "1.0.0-beta.3+x86-64.debug"
    MyApp().version.isStable // false

## Topics

<doc:SemverRules>
