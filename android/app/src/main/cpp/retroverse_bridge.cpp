#include <jni.h>
#include <android/log.h>
#include <stddef.h>
#include "retroverse_bridge.h"

#define LOG_TAG "RetroVerseBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

EXPORT void retro_init(void) {
    LOGI("retro_init called - Initializing Sega Genesis core");
}

EXPORT void retro_deinit(void) {
    LOGI("retro_deinit called - Cleaning up resources");
}

EXPORT void retro_run(void) {
    // Run emulation loop for 1 frame
}

EXPORT size_t retro_serialize_size(void) {
    LOGI("retro_serialize_size queried");
    return 1024 * 512; // 512 KB standard Genesis state buffer
}

}
