"""An aspect which visits everything."""

load("providers.bzl", "PackageAttributeInfo", "PackageMetadataInfo")

DEBUG_LEVEL=1

TransitiveMetadataInfo = provider(
    doc = """The transitive set of metadata applicable to a target.""",
    fields = {
        "top_level_target": "Label: The top level target label we are examining.",
        "metadata": "depset(TransitiveMetatdataInfo)",
        "package_info": "depset(PackageMetadataInfo)",

        "target": "Label: A target which will be associated with some metadata.",
        "deps": "depset(provider): The transitive list of dependencies that have licenses.",
    },
)

def _gather_package_attributes_impl(target, ctx):
    """Collect package metadata info from myself and my deps.

    """

    # A hack until https://github.com/bazelbuild/rules_license/issues/89 is
    # fully resolved. If exec is in the bin_dir path, then the current
    # configuration is probably cfg = exec.
    if "-exec-" in ctx.bin_dir.path:
        return TransitiveMetadataInfo()

    # First we gather my direct metadata providers
    got_providers = []
    package_info = []
    if DEBUG_LEVEL > 1:
        print("==============================================\n %s (%s) \n" % (target.label, ctx.rule.kind))

    if hasattr(ctx.rule.attr, "package_metadata"):
        package_metadata = ctx.rule.attr.package_metadata
    else:
        package_metadata = []
    for dep in package_metadata:
        if DEBUG_LEVEL > 1:
            print("checking", dep.label)
        for m_p in [PackageAttributeInfo, PackageMetadataInfo]:
            if m_p in dep:
                info = dep[m_p]
                print("%s: has %s:\n          %s" % (target.label, info.id, info))
                got_providers.append(info)

    #if DEBUG_LEVEL > 0 and got_providers:
    #    print("  GOT: ", target.label, got_providers)

    # Now gather transitive collection of providers from the children
    # this target depends upon.
    trans_metadata = []
    trans_package_metadata = []
    trans_deps = []
    """
    _get_transitive_metadata(
        ctx = ctx,
        trans_metadata = trans_metadata,
        trans_package_metadata = trans_package_metadata,
        trans_deps = trans_deps,
        provider = provider_factory,
        filter_func = filter_func,
        traces = traces,
    )
    """

    return [TransitiveMetadataInfo(
        target = target.label,
        metadata = depset(tuple(got_providers), transitive = trans_metadata),
    )]


gather_package_attributes = aspect(
    doc = """Collects metadata providers into a single TransitiveMetadataInfo provider.""",
    implementation = _gather_package_attributes_impl,
    attr_aspects = ["*"],
    provides = [TransitiveMetadataInfo],
    apply_to_generating_rules = True,
)


def _visit_impl(ctx):
    # The code below just dumps the collected metadata providers in a somewhat
    # pretty printed way.  In reality, we need to read the files associated with
    # each attribute to get the real data. So this should be a rule to pass
    # all the files to a helper which generates a formated report.
    # That is clearly a job for another day.
    out = []
    for dep in ctx.attr.targets:
        if TransitiveMetadataInfo not in dep:
            continue
        t_m_i = dep[TransitiveMetadataInfo]
        out.append("Target: %s\n" % str(t_m_i.target))
        for item in t_m_i.metadata.to_list():
           kind = item.kind if hasattr(item, "kind") else "<unknown>"
           props = ["kind: %s" % kind]
           for field in sorted(dir(item)):
               # skip files because it is a depset of files we need to read.
               if field in ("files", "kind"):
                   continue
               value = getattr(item, field)
               if field == "attributes":
                   props.append("%s: %s" % (field, value.path))
               else:
                   props.append("%s: %s" % (field, value))
           out.append("   %s\n" % ", ".join(props))
    ctx.actions.write(ctx.outputs.out, "".join(out) + "\n")
    print("".join(out) + "\n")
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

visit = rule(
    implementation = _visit_impl,
    doc = """Internal implementation method for visit().""",
    attrs = {
        "targets": attr.label_list(
            doc = """List of targets to collect LicenseInfo for.""",
            aspects = [gather_package_attributes],
        ),
        "out": attr.output(
            doc = """Output file.""",
            mandatory = True,
        ),
    },
)

def _get_transitive_metadata(
        ctx,
        trans_metadata, 
        trans_package_metadata, 
        trans_deps, 
        provider, 
        filter_func = None,
        traces = None):
    """Gather the provider instances of interest from our children

    Args:
        ctx: the ctx
        # TODO
    """    
    attrs = [attr for attr in dir(ctx.rule.attr)]
    for name in attrs:
        if filter_func and not filter_func(ctx, name):
            if DEBUG_LEVEL > 2:
                print("Triming attribute %s of %s" % (name, ctx.rule.kind))
            continue
        if DEBUG_LEVEL > 4:
            print("CHECKING attribute %s of %s" % (name, ctx.rule.kind))

        attr_value = getattr(ctx.rule.attr, name)
        # Make scalers into a lists for convenience.
        if type(attr_value) != type([]):
            attr_value = [attr_value]

        for dep in attr_value:
            # Ignore anything that isn't a target
            if type(dep) != "Target":
                continue

            # Targets can also include things like input files that won't have the
            # aspect, so we additionally check for the aspect rather than assume
            # it's on all targets.  Even some regular targets may be synthetic and
            # not have the aspect. This provides protection against those outlier
            # cases.
            if provider in dep:
                info = dep[provider]
                #XXif info.deps:
                #XX    trans_deps.append(info.deps)
                if hasattr(info, "traces") and getattr(info, "traces"):
                    for trace in info.traces:
                        traces.append("(" + ", ".join([str(ctx.label), ctx.rule.kind, name]) + ") -> " + trace)

                # We only need one or the other of these stanzas.
                # If we use a polymorphic approach to metadata providers, then
                # this works.
                if hasattr(info, "metadata"):
                    if info.metadata:
                        trans_metadata.append(info.metadata)

                # But if we want more precise type safety, we would have a
                # trans_* for each type of metadata. That is not user
                # extensibile.
                if hasattr(info, "package_info"):
                    if info.package_info:
                        trans_package_metadata.append(info.package_info)

