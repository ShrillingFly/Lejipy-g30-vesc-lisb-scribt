VESC_TOOL ?= $(if $(wildcard ./vesc_tool),./vesc_tool,vesc_tool)

PKG = g30_dashboard_race.vescpkg

all: $(PKG)

$(PKG): pkgdesc.qml ui.qml g30_dashboard_race.lisp README.md version
	$(VESC_TOOL) --buildPkgFromDesc pkgdesc.qml --testPkgDesc 'vesc:maxim 120' --testPkgDesc 'vesc:pronto'

clean:
	rm -f $(PKG)

.PHONY: all clean
