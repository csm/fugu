/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */
 
#include <Security/SecBase.h>
#include <Security/SecKeychain.h>
#include <sys/types.h>
#include <sys/file.h>
#include <sys/param.h>
#include <errno.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>
#include "keychain.h"

extern int			errno;

    char *
getpwdfromkeychain( const char *service, const char *account, OSStatus *error )
{
    OSStatus 			err;
    SecKeychainRef		skcref;
    UInt32 			len;
    char			*password;

    err = SecKeychainCopyDefault( &skcref );
    
    if ( err ) {
        syslog( LOG_ERR, "SecKeychainCopyDefault failed" );
        return( NULL );
    }
    
    if (( password = ( char * )malloc( _PASSWORD_LEN + 1 )) == NULL ) {
        syslog( LOG_ERR, "malloc: %s", strerror( errno ));
        return( NULL );
    }
    
    err = SecKeychainFindGenericPassword( skcref,
                strlen( service ), service,
                strlen( account ), account, &len, ( void ** )&password, NULL );

    *error = err;
    switch ( err ) {
    case 0:
        break;
    case errSecItemNotFound:
        syslog( LOG_INFO, "keychain item not found" );
        free( password );
        return( NULL );
    case errSecAuthFailed:
        syslog( LOG_ERR, "authorization failed." );
        free( password );
        return( NULL );
    case errSecNoDefaultKeychain:
        syslog( LOG_INFO, "No default keychain!" );
        free( password );
        return( NULL );
    case errSecBufferTooSmall:
        /* if the buffer's too small, make it really large and try again */
        syslog( LOG_INFO, "buffer too small, realloc'ing" );
        if (( password = ( char * )realloc( password, 4096 )) == NULL ) {
            syslog( LOG_ERR, "realloc: %s", strerror( errno ));
            free( password );
            return( NULL );
        }
        err = SecKeychainFindGenericPassword( skcref,
                strlen( service ), service,
                strlen( account ), account, &len, ( void ** )&password, NULL );
        if ( ! err ) break;
        free( password );
        return( NULL );
    default:
        syslog( LOG_ERR, "unknown error" );
        free( password );
        return( NULL );
    }
    
    password[ len ] = '\0';
    
    /* returns malloc'd bytes which must be free'd */
    return( password );
}

    void
addpwdtokeychain( const char *service, const char *account, const char *password )
{
    OSStatus		err;
    SecKeychainRef	skcref;

    err = SecKeychainCopyDefault( &skcref );
    
    if ( err ) {
        syslog( LOG_ERR, "SecKeychainCopyDefault failed. Make sure you have a keychain available." );
        return;
    }
    
    err = SecKeychainAddGenericPassword( skcref,
                strlen( service ), service,
                strlen( account ), account,
                strlen( password ),
                ( const void * )password, NULL );
    
    switch ( err ) {
    case 0:
        break;
    case errSecDuplicateItem:
        syslog( LOG_INFO, "keychain item already exists." );
        break;
    case errSecAuthFailed:
        syslog( LOG_ERR, "authorization failed." );
        break;
    default:
        syslog( LOG_ERR, "unknown error adding password to keychain" );
        break;
    }
}