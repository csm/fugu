#include <ApplicationServices/ApplicationServices.h>
#include "ODBEditorSuite.h"

int	aesend( char *path, OSType eventType, char *sendertoken );
void	odb_close( char *path );
void	odb_save( char *path, char *sendertoken );
