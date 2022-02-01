# ``SemanticVersion``
Concrete type representing a semantic version as defined in semver 2.0.0 https://semver.org
<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->
## Overview

SemanticVersion defines a concrete type `SemanticVersion` capable of representing a semantic version number. To make a type versionable, just conform to `SemanticVersionable` protocol.

## Example

Make struct/class versionable

    extension MyApp : SemanticVersionable {
        var version: SemanticVersion {
            return SemanticVersion(major: 1, minor: 0, patch: 0,
                                   preReleaseIdentifiers: ["rc", "3"],
                                   buildMetadataIdentifiers: ["arm64", "debug"])!
        }
    }
    MyApp().version.description // "1.0.0-rc.3+arm64.debug"
    MyApp().version.isStable // false

## Topics

<doc:SemverRules>
