#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import <libwebp/demux.h>
#import <libwebp/mux.h>
#import <libwebp/decode.h>
#import <libwebp/encode.h>
#import <libwebp/types.h>
#import <libwebp/mux_types.h>
#import <libwebp/format_constants.h>

FOUNDATION_EXPORT double libwebpVersionNumber;
FOUNDATION_EXPORT const unsigned char libwebpVersionString[];

