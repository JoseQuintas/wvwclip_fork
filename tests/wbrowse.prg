#include "inkey.ch"
#include "wvwclip.ch"

REQUEST DBFCDX

FUNCTION Main()

LOCAL lDummy := .F.
LOCAL oBrowse := NIL

PRIVATE GetList := {}
PRIVATE oApp

SET DEFAULT TO .\data
SET EVENTMASK TO INKEY_ALL - INKEY_MOVE

hb_cdpSelect( 255 )

SetMode( 8, 28 )

oApp := WApp():New( .F., , "Browse Example" )

USE currency INDEX currency VIA "DBFCDX" SHARED

// Setup browse.
oBrowse           := TBrowse():New()
oBrowse:colorspec := 'W/N, N/W'

// Add column.
oBrowse:AddColumn( TBColumn():New( , { || Pad( currency->currid +' '+ ;
   currency->descript +' '+ currency->symb, 29 ) } ) )
@ 00, 01 LABEL 'Currencies' FONT HeadFont()
@ 02, 01 LABEL 'ID'
@ 02, 05 LABEL 'Currency'
@ 02, 21 LABEL 'Symbol'

@ 03, 01, 06, 26 GET lDummy TBROWSE oBrowse GUISEND forceStable()

READ SAVE

USE

oApp:WCLS()

RETURN NIL
