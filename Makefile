APP_NAME    := TabDoubleClick
BUILD_DIR   := build
APP_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
VERSION     := 1.0.0
INSTALL_DIR := $(HOME)/Applications
DIST_DIR    := dist

.PHONY: all build install uninstall clean dist help

all: build

## build    编译生成 build/TabDoubleClick.app
build:
	@./scripts/build.sh

## install  编译并安装到 ~/Applications，然后启动
install:
	@./scripts/install.sh

## dist     打包成可分发的 zip（dist/TabDoubleClick-$(VERSION).zip）
dist: build
	@mkdir -p $(DIST_DIR)
	@rm -f $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip
	@cd $(BUILD_DIR) && ditto -c -k --sequesterRsrc --keepParent $(APP_NAME).app ../$(DIST_DIR)/$(APP_NAME)-$(VERSION).zip
	@echo "已生成 $(DIST_DIR)/$(APP_NAME)-$(VERSION).zip"

## uninstall 退出并删除已安装的程序（不清理授权记录）
uninstall:
	@pkill -f "$(INSTALL_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "已删除 $(INSTALL_DIR)/$(APP_NAME).app"
	@echo "如需清除授权记录：系统设置 → 隐私与安全性 → 辅助功能 → 选中 $(APP_NAME) 点 −"

## clean    清理构建产物
clean:
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "已清理"

## help     显示帮助
help:
	@grep '^##' Makefile | sed 's/^## /  /'
