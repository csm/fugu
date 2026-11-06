/*
 * Copyright (c) 2003 Regents of The University of Michigan.
 * All Rights Reserved.  See COPYRIGHT.
 */

#include <Security/SecBase.h>

char *getpwdfromkeychain( const char *service, const char *account, OSStatus *error );
void addpwdtokeychain( const char *service, const char *account, const char *password );

