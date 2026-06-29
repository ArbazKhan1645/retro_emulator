#ifndef RETROVERSE_BRIDGE_H
#define RETROVERSE_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

#define EXPORT __attribute__((visibility("default"))) __attribute__((used))

EXPORT void retro_init(void);
EXPORT void retro_deinit(void);
EXPORT void retro_run(void);
EXPORT size_t retro_serialize_size(void);

#ifdef __cplusplus
}
#endif

#endif // RETROVERSE_BRIDGE_H
