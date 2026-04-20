/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import "SCPTransfer.h"
#import "SCPController.h"
#import "NSString(SSHAdditions).h"

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/param.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <util.h>

#include "argcargv.h"
#include "sshversion.h"


@implementation SCPTransfer

extern char	**environ;

int		scpconnecting = 0;


- ( id )init
{
    scppid = 0;
    return(( self = [ super init ] ) ? self : nil );
}

- ( int )closeMasterFD
{
    if ( close( masterfd ) < 0 ) {
        return( -1 );
    }
    
    return( 0 );
}

- ( void )parseProgressOutputString: ( char * )string
            forController: ( SCPController * )controller
{
    int			tac, i, pc_index = -1;
    char		*tmp, **tav, *p;
    char		*t_rate, *t_amount, *t_eta;
    char		filename[ MAXPATHLEN ] = { 0 };
    
    if (( tmp = strdup( string )) == NULL ) {
	perror( "strdup" );
	exit( 2 );
    }
    
    if (( tac = argcargv( tmp, &tav )) < 5 ) {
	/* not a transfer progress line we're interested in */
	free( tmp );
	return;
    }
    
    for ( i = ( tac - 1 ); i >= 0; i-- ) {
	if (( p = strrchr( tav[ i ], '%' )) != NULL ) {
	    /* found the %-done field */
	    pc_index = i;
            *p = '\0';
	    break;
	}
    }
    
    /* OpenSSH 3.7 and above use a different progress output in scp */
    if ( sshversion() > 3.6 ) {
        t_amount = tav[ pc_index + 1 ];
        
        if ( pc_index == ( tac - 5 )) {
            t_eta = tav[ pc_index + 3 ];
        } else {
            t_eta = "--:--";
        }
    } else {
        int		pos;

        if ( strcmp( "ETA", tav[ tac - 1 ] ) == 0 ) {
            t_eta = tav[ tac - 2 ];
            
            if ( ! isdigit( *tav[ tac - 3 ] )) {
                pos = ( tac - 4 );
            } else {
                pos = ( tac - 3 );
            }
        } else {
            t_eta = tav[ tac - 1 ];
            if ( ! isdigit( *tav[ tac - 2 ] )) {
                pos = ( tac - 3 );
            } else {
                pos = ( tac - 2 );
            }
        }
        t_amount = tav[ pos ];
    }
    t_rate = tav[ pc_index + 2 ];
    (void)t_rate;

    /* everything before the %-done field is a filename */
    ( void )strlcpy( filename, tav[ 0 ], sizeof( filename ));
    for ( i = 1; i < pc_index; i++ ) {
        ( void )strlcat( filename, tav[ i ], sizeof( filename ));
    }

    NSString *_fname   = [ NSString stringWithUTF8String: filename ];
    NSString *_pc      = [ NSString stringWithUTF8String: tav[ pc_index ] ];
    NSString *_eta     = [ NSString stringWithUTF8String: t_eta ];
    NSString *_amount  = [ NSString stringWithUTF8String: t_amount ];
    free( tmp );

    dispatch_async( dispatch_get_main_queue(), ^{
        [ controller fileCopying: _fname
                        updateWithPercentDone: ( char * )[ _pc UTF8String ]
                        eta: ( char * )[ _eta UTF8String ]
                        bytesCopied: ( char * )[ _amount UTF8String ]];
    });
}

- ( void )scpConnect: ( char * )userathost toPort: ( char * )portnumber
                forItem: ( char * )localfile scpType: ( int )scpType
                fromController: ( SCPController * )controller
{
    fd_set		readmask;
    FILE		*mfp;
    int			copying = 0;
    int			status, validpw = 0, noscp = 0;
    __attribute__((unused)) int pwsent = 0, threestrikes = 0;
    char		*unknownmsg;
    char		ttyname[ MAXPATHLEN ];
    unichar		buf[ MAXPATHLEN ];
    char		executable[ MAXPATHLEN], portarg[ MAXPATHLEN ], *execargs[ 6 ];
    NSString		*scpBinary;
  
    dispatch_async( dispatch_get_main_queue(), ^{ [ controller clearLog ]; });

    if (( scpBinary = [ NSString pathForExecutable: @"scp" ] ) == nil ) {
	NSLog( @"Couldn't find scp!" );
	return;
    }	    
    if ( [ scpBinary length ] >= MAXPATHLEN ) {
	NSLog( @"scpBinary: too long" );
	return;
    }
    strcpy( executable, [ scpBinary UTF8String ] );
    execargs[ 0 ] = executable;

    scpconnecting = 1;
    {
        NSString *_launch = [ NSString stringWithFormat: @"scp launch path is %s.\n", executable ];
        dispatch_async( dispatch_get_main_queue(), ^{ [ controller addToLog: _launch ]; });
    }
    
    if ( snprintf( portarg, MAXPATHLEN, "-oPort=%s", portnumber ) > ( MAXPATHLEN - 1 )) {
        NSLog( @"portarg exceeds bounds" );
    }
    
    execargs[ 1 ] = "-r";
    execargs[ 2 ] = portarg;
    execargs[ 3 ] = ( scpType == 0 ? localfile : userathost );
    execargs[ 4 ] = ( scpType == 0 ? userathost : localfile );
    execargs[ 5 ] = NULL;
    
    if ( scppid == forkpty( &masterfd, ttyname, NULL, NULL )) {
        if ( fcntl( masterfd, F_SETFL, O_NONBLOCK ) < 0 ) {	/* prevent master from blocking */
        }
        
        {
            pid_t _pid = scppid;
            int   _fd  = masterfd;
            NSString *_tty = [ NSString stringWithFormat: @"Slave terminal device is %s.\n", ttyname ];
            NSString *_mfd = [ NSString stringWithFormat: @"Master fd is %d.\n", masterfd ];
            dispatch_async( dispatch_get_main_queue(), ^{
                [ controller setSCPPID: _pid ];
                [ controller setMasterFD: _fd ];
                [ controller addToLog: _tty ];
                [ controller addToLog: _mfd ];
            });
        }
                                    
        if (( mfp = fdopen( masterfd, "r" )) == NULL ) {
            NSLog( @"fdopen master fd returned NULL" );
            exit( 2 );
        }
        setvbuf( mfp, NULL, _IONBF, 0 );
        
        for ( ;; ) {
            NSAutoreleasePool	*pool = [[ NSAutoreleasePool alloc ] init ];
	    FD_ZERO( &readmask );
            FD_SET( masterfd, &readmask );
            if ( select( masterfd + 1, &readmask, NULL, NULL, NULL ) < 0 ) {
                NSLog( @"select() returned a value less than zero" );
                return;
            }
            
            if ( FD_ISSET( masterfd, &readmask )) {
                if ( fgets(( char * )buf, MAXPATHLEN, mfp ) == NULL ) break;

                if (( strstr(( char * )buf, "Password:" ) != NULL
                        || strstr(( char * )buf, "password:" ) != NULL
                        || strstr(( char * )buf, "passphrase" ) != NULL )
                        && !validpw ) {
                    if ( scpconnecting ) {
                        NSString *_prompt = [ NSString stringWithUTF8String: ( char * )buf ];
                        dispatch_async( dispatch_get_main_queue(), ^{
                            [ controller authenticateWithPrompt: ( char * )[ _prompt UTF8String ]];
                        });
                    }
                    pwsent = 1;
                } else {
                    if ( strncmp(( char * )buf, "Permission denied, ",
                                    strlen( "Permission denied, " )) == 0 ) {
                        dispatch_async( dispatch_get_main_queue(), ^{ [ controller passError ]; });
                        pwsent = 0;
                        threestrikes++;
                    } else if ( strstr(( char * )buf, "passphrase for key" ) != NULL ) {
                        pwsent = 0;
                        threestrikes = 0;	/* if pubkey auth fails, password prompt will appear */
                    } else if ( strstr(( char * )buf, "scp: Command not found" ) != NULL ) {
                        NSString *_err = [ NSString stringWithUTF8String: ( char * )buf ];
                        dispatch_async( dispatch_get_main_queue(), ^{
                            [ controller sessionError: _err ];
                        });
                        noscp++;
                    } else if ( strncmp(( char * )buf, "The auth", strlen( "The auth" )) == 0 ) {
                        unknownmsg = strdup(( char * )buf );
                        NSString *_log = [ NSString stringWithUTF8String: ( char * )buf ];
                        dispatch_async( dispatch_get_main_queue(), ^{
                            [ controller addToLog: _log ];
                        });
                        fgets(( char * )buf, MAXPATHLEN, mfp ); /* get rest of message */
                        NSString *_query = [ NSString stringWithFormat: @"%s%s",
                                                unknownmsg, ( char * )buf ];
                        dispatch_async( dispatch_get_main_queue(), ^{
                            [ controller getContinueQueryWithString: _query ];
                        });
                        free( unknownmsg );
                    } else if ( strncmp(( char * )buf, "Secure ", strlen( "Secure" )) == 0 ) {
                        NSString *_err = [ NSString stringWithUTF8String: ( char * )buf ];
                        dispatch_async( dispatch_get_main_queue(), ^{
                            [ controller sessionError: _err ];
                        });
                    }
                }
                if ( strchr(( char * )buf, '%' ) != NULL ) {
                    if ( ! copying ) {
                        dispatch_async( dispatch_get_main_queue(), ^{ [ controller secureCopy ]; });
                        copying = 1;
                    } else {
                        [ self parseProgressOutputString: ( char * )buf
                                forController: controller ];
                    }
                }

                if ( strstr(( char * )buf, "Operation timed out" ) != NULL
                        || strstr(( char * )buf, "REMOTE HOST IDENTIFICATION HAS CHANGED" ) != NULL ) {
                    char *p = strdup(( char * )buf ), *q;
                    if (( q = strrchr( p, '\r' )) != NULL ) *q = '\0';
                    NSString *_err = [ NSString stringWithUTF8String: p ];
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [ controller sessionError: _err ];
                    });
                    free( p );
                }

                NSString *_line = [ NSString stringWithUTF8String: ( char * )buf ];
                dispatch_async( dispatch_get_main_queue(), ^{ [ controller addToLog: _line ]; });
                memset(( char * )buf, '\0', strlen(( char * )buf ));
                [ pool drain ];
                if ( noscp ) break;
            }
        }

        scppid = wait( &status );

        ( void )close( masterfd );
        {
            NSString *_tail = [ NSString stringWithUTF8String: ( char * )buf ];
            pid_t _pid = scppid;
            int   _st  = status;
            dispatch_async( dispatch_get_main_queue(), ^{
                [ controller addToLog: _tail ];
                [ controller addToLog: [ NSString stringWithFormat:
                            @"\nscp task with pid %d ended with status %d.\n",
                            _pid, WEXITSTATUS( _st ) ]];
                [ controller addToLog: @"\n\n" ];
                [ controller secureCopyFinishedWithStatus: WEXITSTATUS( _st ) ];
                if ( WIFEXITED( _st )) {
                    [ controller addToLog: @"Normal exit\n" ];
                } else if ( WIFSIGNALED( _st )) {
                    [ controller addToLog: @"WIFSIGNALED: " ];
                    [ controller addToLog: [ NSString stringWithFormat: @"signal = %d\n", _st ]];
                } else if ( WIFSTOPPED( _st )) {
                    [ controller addToLog: @"WIFSTOPPED\n" ];
                }
            });
        }
        scppid = 0;
    } else if ( scppid < 0 ) {
        NSLog( @"forkpty failed: %s", strerror( errno ));
    } else {
        execve( executable, ( char ** )execargs, environ );
        NSLog( @"execve failed: %s", strerror( errno ));
        
        _exit( 2 );						/* shouldn't get here */
    }
}

@end
