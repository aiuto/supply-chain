load("rules.bzl", "license", "package_metadata")
load("visit.bzl", "visit")

package(
    default_package_metadata = [":package_metadata"],
    default_visibility = ["//visibility:public"],
)

filegroup(
    name = "srcs",
    srcs = [
        "providers.bzl",
        "rules.bzl",
	":vis",
    ],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "vis",
    srcs = [
        "visit.bzl",
    ],
)

package_metadata(
    name = "package_metadata",
    attributes = [
        ":license",
    ],
    visibility = ["//visibility:public"],
)

license(
    name = "license",
    kind = "//licenses/spdx:Apache-2.0",
    text = "LICENSE",
)

visit(
    name = "visit_srcs",
    targets = [":srcs"],
    out = "visited.txt",
)


filegroup(name = "g1", srcs = [":vis"], package_metadata = [":license"])

visit(name = "visit_g1", targets = [":g1"], out = "visit_g1.txt")

visit(name = "visit_g2", targets = [":package_metadata"], out = "visit_g2.txt")

