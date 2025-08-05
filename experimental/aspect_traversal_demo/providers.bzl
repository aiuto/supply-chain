
visibility("public")

def _init_pai(kind, attributes, files = []):
    return {
	"id": "PackageAttibuteInfo",
        "attributes": attributes,
        "files": depset(
            direct = [
                attributes,
            ],
            transitive = files,
        ),
        "kind": kind,
    }

PackageAttributeInfo, _create_pai = provider(
    doc = """innner rule.""",
    fields = {
	"id": """The constant PackageAttibuteInfo""",
        "attributes": """dict of data""",
        "files": """files of the json dump of the data""",
        "kind": """The identifier of the attribute.""",
    },
    init = _init_pai,
)

def _init_pmi(metadata, files = []):
    return {
	"id": "PackageMetadataInfo",
        "files": depset(
            direct = [
                metadata,
            ],
            transitive = files,
        ),
        "metadata": metadata,
    }

PackageMetadataInfo, _create_pmi = provider(
    doc = """Outer rule.""",
    fields = {
	"id": """The constant PackageMetadataInfo""",
        "files": """collection of files from PackageAttributeInfo""",
        "metadata": """more""",
    },
    init = _init_pmi,
)
