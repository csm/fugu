/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#include <Security/Security.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include "keychain.h"

extern int			errno;

    char *
getpwdfromkeychain( const char *service, const char *account, OSStatus *error )
{
    CFStringRef		svcRef  = CFStringCreateWithCString( NULL, service,  kCFStringEncodingUTF8 );
    CFStringRef		acctRef = CFStringCreateWithCString( NULL, account, kCFStringEncodingUTF8 );
    CFDataRef		result  = NULL;
    char		*password = NULL;

    CFDictionaryRef query = CFDictionaryCreate( NULL,
        ( const void ** )( CFTypeRef[] ){
            kSecClass, kSecAttrService, kSecAttrAccount,
            kSecReturnData, kSecMatchLimit
        },
        ( const void ** )( CFTypeRef[] ){
            kSecClassGenericPassword, svcRef, acctRef,
            kCFBooleanTrue, kSecMatchLimitOne
        }, 5,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks );

    *error = SecItemCopyMatching( query, ( CFTypeRef * )&result );
    CFRelease( query );
    CFRelease( svcRef );
    CFRelease( acctRef );

    switch ( *error ) {
    case errSecSuccess:
        break;
    case errSecItemNotFound:
        syslog( LOG_INFO, "keychain item not found" );
        return NULL;
    case errSecAuthFailed:
        syslog( LOG_ERR, "authorization failed." );
        return NULL;
    default:
        syslog( LOG_ERR, "SecItemCopyMatching: error %d", ( int )*error );
        return NULL;
    }

    CFIndex len = CFDataGetLength( result );
    if (( password = ( char * )malloc( (size_t)len + 1 )) == NULL ) {
        syslog( LOG_ERR, "malloc: %s", strerror( errno ));
        CFRelease( result );
        return NULL;
    }
    memcpy( password, CFDataGetBytePtr( result ), (size_t)len );
    password[ len ] = '\0';
    CFRelease( result );

    /* returns malloc'd bytes which must be free'd */
    return password;
}

    void
addpwdtokeychain( const char *service, const char *account, const char *password )
{
    CFStringRef  svcRef  = CFStringCreateWithCString( NULL, service,  kCFStringEncodingUTF8 );
    CFStringRef  acctRef = CFStringCreateWithCString( NULL, account, kCFStringEncodingUTF8 );
    CFDataRef    pwdData = CFDataCreate( NULL, ( const UInt8 * )password, strlen( password ));

    CFDictionaryRef item = CFDictionaryCreate( NULL,
        ( const void ** )( CFTypeRef[] ){
            kSecClass, kSecAttrService, kSecAttrAccount, kSecValueData
        },
        ( const void ** )( CFTypeRef[] ){
            kSecClassGenericPassword, svcRef, acctRef, pwdData
        }, 4,
        &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks );

    OSStatus err = SecItemAdd( item, NULL );
    CFRelease( item );
    CFRelease( svcRef );
    CFRelease( acctRef );
    CFRelease( pwdData );

    switch ( err ) {
    case errSecSuccess:
        break;
    case errSecDuplicateItem:
        syslog( LOG_INFO, "keychain item already exists." );
        break;
    case errSecAuthFailed:
        syslog( LOG_ERR, "authorization failed." );
        break;
    default:
        syslog( LOG_ERR, "SecItemAdd: error %d", ( int )err );
        break;
    }
}
