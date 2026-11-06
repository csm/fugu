/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#import <Cocoa/Cocoa.h>

@class SFTPController;

@protocol SFTPTServerInterface

- ( void )connectToServerWithParams: ( NSArray * )params
                    fromController: ( SFTPController * )controller;

- ( void )collectListingFromMaster: ( int )master fileStream: ( FILE * )mf
            forController: ( SFTPController * )controller;
- ( int )atSftpPrompt;
- ( pid_t )getSftpPid;

@end

@interface SFTPTServer : NSObject <SFTPTServerInterface> {
@private
    int			atprompt;
    NSString		*remoteDirBuf;
    NSString		*_currentTransferName;
    NSString            *_sftpRemoteObjectList;
}

- ( id )init;
- ( NSString * )retrieveUnknownHostKeyFromStream: ( FILE * )stream;
- ( NSMutableDictionary * )remoteObjectFromSFTPLine: ( char * )line;
- ( BOOL )checkForPasswordPromptInBuffer: ( char * )buf;
- ( BOOL )hasDirectoryListingFormInBuffer: ( char * )buf;

@end
