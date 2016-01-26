# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# BE CAREFUL!  This makefile handles a postflight_all rule for a
# multi-project build, so DON'T rely on anything that might differ between
# the two OBJDIRs.

ifndef OBJDIR
OBJDIR = $(MOZ_OBJDIR)/$(firstword $(MOZ_BUILD_PROJECTS))
endif

DIST_ARCH = $(OBJDIR)/dist
DIST_UNI = $(DIST_ARCH)/universal

topsrcdir = $(TOPSRCDIR)
DEPTH = $(OBJDIR)
include $(OBJDIR)/config/autoconf.mk

core_abspath = $(if $(filter /%,$(1)),$(1),$(CURDIR)/$(1))

DIST = $(OBJDIR)/dist

postflight_all:
	mkdir -p $(DIST_UNI)/$(MOZ_PKG_APPNAME)
# Stage a package for buildsymbols to be happy.
	$(MAKE) -C $(OBJDIR)/$(MOZ_BUILD_APP)/installer \
	   PKG_SKIP_STRIP=1 stage-package
ifdef ENABLE_TESTS
# Now, repeat the process for the test package.
	$(MAKE) -C $(OBJDIR_ARCH_1) UNIVERSAL_BINARY= CHROME_JAR= package-tests
	$(MAKE) -C $(OBJDIR_ARCH_2) UNIVERSAL_BINARY= CHROME_JAR= package-tests
	rm -rf $(DIST_UNI)/test-package-stage
# automation.py differs because it hardcodes a path to
# dist/bin. It doesn't matter which one we use.
	if test -d $(DIST_ARCH_1)/test-package-stage -a                 \
                -d $(DIST_ARCH_2)/test-package-stage; then              \
           cp $(DIST_ARCH_1)/test-package-stage/mochitest/automation.py \
             $(DIST_ARCH_2)/test-package-stage/mochitest/;              \
           cp -RL $(DIST_ARCH_1)/test-package-stage/mochitest/extensions/specialpowers \
             $(DIST_ARCH_2)/test-package-stage/mochitest/extensions/;              \
           cp $(DIST_ARCH_1)/test-package-stage/xpcshell/automation.py  \
             $(DIST_ARCH_2)/test-package-stage/xpcshell/;               \
           cp $(DIST_ARCH_1)/test-package-stage/reftest/automation.py   \
             $(DIST_ARCH_2)/test-package-stage/reftest/;                \
           cp -RL $(DIST_ARCH_1)/test-package-stage/reftest/specialpowers \
             $(DIST_ARCH_2)/test-package-stage/reftest/;              \
           $(TOPSRCDIR)/build/macosx/universal/unify                 \
             --unify-with-sort "\.manifest$$" \
             --unify-with-sort "all-test-dirs\.list$$"               \
             $(DIST_ARCH_1)/test-package-stage                          \
             $(DIST_ARCH_2)/test-package-stage                          \
             $(DIST_UNI)/test-package-stage; fi
endif
