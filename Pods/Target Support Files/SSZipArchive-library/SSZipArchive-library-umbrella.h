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

#import <SSZipArchive-library/SSZipArchive.h>
#import <SSZipArchive-library/SSZipCommon.h>
#import <SSZipArchive-library/ZipArchive.h>

FOUNDATION_EXPORT double SSZipArchiveVersionNumber;
FOUNDATION_EXPORT const unsigned char SSZipArchiveVersionString[];

