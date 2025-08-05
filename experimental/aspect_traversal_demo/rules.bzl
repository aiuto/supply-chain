"""Declares rule `package_metadata`."""

load("providers.bzl", "PackageAttributeInfo", "PackageMetadataInfo")

visibility("public")

def _package_metadata_impl(ctx):
    attributes = [a[PackageAttributeInfo] for a in ctx.attr.attributes]

    print("In package_metadata rule")
    metadata = ctx.actions.declare_file("{}.package-metadata.json".format(ctx.attr.name))

    # Prints the paths of the files written by all the attributes.
    ctx.actions.write(
        output = metadata,
        content = json.encode({
            "attributes": {a.kind: a.attributes.path for a in attributes},
            "label": str(ctx.label),
        }),
    )
    return [
        DefaultInfo(
            files = depset(
                direct = [
                    metadata,
                ],
            ),
        ),
        PackageMetadataInfo(
            metadata = metadata,
            files = [a.files for a in attributes],
        ),
    ]


_package_metadata = rule(
    implementation = _package_metadata_impl,
    attrs = {
        "attributes": attr.label_list(
            mandatory = False,
            providers = [
                PackageAttributeInfo,
            ],
        ),
        "purl": attr.string()
    },
    provides = [
        PackageMetadataInfo,
    ],
    doc = """Bundles a set of PackageAttributeInfos""",
)

def package_metadata(
        name,
        attributes = [],
        purl = None,
        visibility = None):
    _package_metadata(
        # `_package_metadata` attributes.
        name = name,
        purl = purl,
        attributes = attributes,

        # Common attributes.
        visibility = visibility,
        applicable_licenses = [],
    )



def _license_impl(ctx):
    print("In license rule. text = %s" % ctx.attr.text)

    attribute = {
        "kind": ctx.attr.kind,
        "label": str(ctx.label),
    }
    files = []

    if ctx.attr.text:
        attribute["text"] = ctx.file.text.path
        files.append(ctx.attr.text[DefaultInfo].files)

    output = ctx.actions.declare_file("{}.package-attribute.json".format(ctx.attr.name))
    ctx.actions.write(
        output = output,
        content = json.encode(attribute),
    )

    return [
        #DefaultInfo(
        #    files = depset(
        #        direct = [
        #            output,
        #        ],
        #    ),
        #),
        PackageAttributeInfo(
            kind = "build.bazel.attribute.license",
            attributes = output,
            files = files,
        ),
    ]



_license = rule(
    implementation = _license_impl,
    attrs = {
        "kind": attr.string(
            mandatory = True,
            doc = """SPDX type""",
        ),
        "text": attr.label(
            mandatory = False,
            allow_single_file = True,
            doc = """file containing hte teext""",
        ),
    },
)


def license(
        name,
        kind,
        text = None,
        visibility = None):
    _license(
        name = name,
        kind = kind,
        text = text,

        # Common attributes.
        visibility = visibility,
        applicable_licenses = [],
    )
