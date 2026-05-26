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

#import <_25519/Curve25519.h>
#import <_25519/Ed25519.h>
#import <_25519/Randomness.h>

FOUNDATION_EXPORT double _25519VersionNumber;
FOUNDATION_EXPORT const unsigned char _25519VersionString[];

