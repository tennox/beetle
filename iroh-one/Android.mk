#
# Glue to call the cargo based build system.
#

LOCAL_PATH:= $(call my-dir)
GONK_DIR := $(abspath $(LOCAL_PATH)/../../)
IROH_ROOT := $(abspath $(LOCAL_PATH))

# Add the ipfsd executable.
include $(CLEAR_VARS)

RUST_TARGET := armv7-linux-androideabi
TARGET_INCLUDE := arm-linux-androideabi

ifeq ($(TARGET_ARCH),x86_64)
RUST_TARGET := x86_64-linux-android
TARGET_INCLUDE := $(RUST_TARGET)
LIBSUFFIX := 64
endif

ifeq ($(TARGET_ARCH),arm64)
RUST_TARGET := aarch64-linux-android
TARGET_INCLUDE := $(RUST_TARGET)
LIBSUFFIX := 64
endif

IPFSD_EXEC := target/$(RUST_TARGET)/release/iroh-one

LOCAL_MODULE := ipfsd
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_SHARED_LIBRARIES := libc libm libdl liblog libcutils
LOCAL_MODULE_PATH := $(TARGET_OUT)/ipfsd

include $(BUILD_SYSTEM)/base_rules.mk

ifndef ANDROID_NDK
LOCAL_NDK := $(HOME)/.mozbuild/android-ndk-r25b
else
LOCAL_NDK := $(ANDROID_NDK)
endif

$(LOCAL_BUILT_MODULE): $(TARGET_CRTBEGIN_DYNAMIC_O) $(TARGET_CRTEND_O)
	@echo "ipfsd: $(IPFSD_EXEC)"
	export TARGET_ARCH=$(RUST_TARGET) && \
	export BUILD_WITH_NDK_DIR=$(LOCAL_NDK) && \
	export GONK_DIR=$(GONK_DIR) && \
	export GONK_PRODUCT=$(TARGET_DEVICE) && \
	(cd $(IROH_ROOT) ; $(SHELL) xcompile.sh --release --strip)

	@touch $(TARGET_OUT_INTERMEDIATES)/EXECUTABLES/ipfsd_intermediates/ipfsd
	@mkdir -p $(@D)
	@mkdir -p $(TARGET_OUT)/ipfsd
	@rm -rf $(TARGET_OUT)/ipfsd/*

	@cp $(IROH_ROOT)/config-gonk.toml $(TARGET_OUT)/ipfsd/config.toml
	@cp $(IROH_ROOT)/../$(IPFSD_EXEC) $(TARGET_OUT)/bin/ipfsd
