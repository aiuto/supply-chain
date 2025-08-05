BZL=bazel8


tst:
	touch *.bzl
	$(BZL) build :srcs
	touch *.bzl
	$(BZL) build :visit_srcs 
	cat bazel-bin/visited.txt
	touch *.bzl
	$(BZL) build :visit_g1
	cat bazel-bin/visit_g1.txt
	$(BZL) build :visit_g2
	cat bazel-bin/visit_g2.txt

