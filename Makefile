
include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for Kid Control
LUCI_DEPENDS:=+nftables
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
