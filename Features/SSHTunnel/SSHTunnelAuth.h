/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Cocoa/Cocoa.h>

@class SSHTunnel;

@protocol SSHTunnelAuthInterface

- ( void )sshTunnelLocalPort: ( char * )lport remoteHost: ( char * )rhost
                remotePort: ( char * )rport tunnelUserAndHost: ( char * )userathost
                tunnelPort: ( char * )tport
                fromController: ( SSHTunnel * )controller;

- ( int )closeMasterFD;

@end

@interface SSHTunnelAuth : NSObject <SSHTunnelAuthInterface>
{
@private
    pid_t	sshpid;
}

- ( id )init;

@end
