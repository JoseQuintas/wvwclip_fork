/****

          System: WVWClip
                  Copyright (c) 2016-2025, Ashfaq Sial

            Date: October, 2025

         Program: WVWCLIPCLASS.PRG
                  Class to manage Visual Clipper via GTWVW.

*/

#include "inkey.ch"
#include "common.ch"
#include "hbclass.ch"
#include "winuser.ch"
#include "getexit.ch"
#include "wvwclip.ch"

#define LABELFONTNAME    "Arial"    //"Segoe UI"
#define LABELFONTSIZE    15         //17
#define DATAFONTNAME     "Consolas"
#define DATAFONTSIZE     20
#define LINESPACING      6

// Array of codeblocks, for each window, used for repainting GUI
// objects via wvw_Paint().
STATIC aGuiObjs := {}

// Array of codeblocks, for each window, used for destroying
// native GUI objects.
STATIC aGUICtls := {}

   MEMVAR GetList

// Window type array for each window.
// Contains window type, linespacing and linespace colour.
STATIC aWinType := {}

CLASS WApp

   DATA cClassName    INIT "WApp"

   DATA lGUIApp       INIT .T.          // GUI App
   DATA cAppIcon      INIT ''           // App icon
   DATA cAppTitle     INIT ''           // App title

   METHOD New( lGUIApp, cAppIcon, cAppTitle ) CONSTRUCTOR
   METHOD WInit( cTitle )
   METHOD WOpen( nTop, nLeft, nBottom, nRight, cTitle, lGUIWin, lCentre, nLineSpacing )
   METHOD WPopup( nTop, nLeft, nBottom, nRight, lGUIWin, lCentre, nLineSpacing )
   METHOD WClose()
   METHOD WCLS()

   HIDDEN:
   METHOD WinSetup( lGUIWin )

ENDCLASS

METHOD New( lGUIApp, cAppIcon, cAppTitle ) CLASS WApp

   LOCAL aPalette // , nLineSpacing, LSColor

   SET EVENTMASK TO INKEY_ALL - INKEY_MOVE

   DEFAULT lGUIApp TO .F.
   DEFAULT cAppIcon TO ''
   DEFAULT cAppTitle TO ''

   ::lGUIApp   := lGUIApp
   ::cAppIcon  := cAppIcon
   ::cAppTitle := cAppTitle

   // Setup GTWVW - Global
   wvw_SetAltF4Close( .F. )
   wvw_SetMainCoord( .F. )          // Standard mode (Default)
   wvw_SetPaintRefresh( 50 )        // 0-Immediate, Minimum 50, Default 100
   wvw_NoStartupSubWindow( .T. )    // Keep new windows hidden (Docs are wrong)
   wvw_SetVertCaret( .F. )
   wvw_SetIcon( , ::cAppIcon )
   wvw_EnableShortcuts( , .T. )
   WVW_SetDefLineSpacing( LINESPACING )

   // Setup colours to match Windows controls.
   aPalette := wvw_GetPalette()
   aPalette[ 08 ] := GetSysColor( COLOR_MENU )        // Menu Bar            W  White
   aPalette[ 09 ] := GetSysColor( COLOR_GRAYTEXT )    // Greyed Text         N+ Grey
   aPalette[ 10 ] := GetSysColor( COLOR_HIGHLIGHT )   // Selected Item       B+ Blue
   aPalette[ 16 ] := GetSysColor( COLOR_WINDOW )      // Window Background   W+ Bright White
   wvw_SetPalette( aPalette )

   // MUST BE DONE BEFORE FONTS ARE SET
   ::WinSetup( ::lGUIApp )

   // Default fonts for native controls.
   wvw_ebSetFont( , LABELFONTNAME, Std_FontSize() + 2, 0, PROOF_QUALITY )
   wvw_pbSetFont( , LABELFONTNAME, Std_FontSize()    , 0, PROOF_QUALITY )
   wvw_cbSetFont( , LABELFONTNAME, Std_FontSize()    , 0, PROOF_QUALITY )
   wvw_cxSetFont( , LABELFONTNAME, Std_FontSize()    , 0, PROOF_QUALITY )
   wvw_sbSetFont( , LABELFONTNAME, Std_FontSize()    , 0, PROOF_QUALITY )

   // This must be here.
   wvw_Size_Ready( .F. )

   ::WInit( ::cAppTitle )

   // Center and display window.
   wvw_SetWindowCentre( , .T., .T. )

   RETURN self

METHOD WinSetup( lGUIWin ) CLASS WApp

   // Setup Line spacing, Line space colour and dataentry fornt.
   // these settings control the height GET fields.

   LOCAL nLineSpacing, LSColor

   DEFAULT lGUIWin TO ::lGUIApp

   IF lGUIWin

      // Settings for GUI window.
      nLineSpacing :=  LINESPACING

      // Default font and colour settings.
      wvw_SetFont( , DATAFONTNAME, DATAFONTSIZE, 0 )
      SetColor( "N/W, W+/B*, , , N/W*" )
      LSColor := ColorToN( "W" )

   ELSE

      // Settings for CUI window.
      // Set screen font - Must keep the width at 11 otherwise windows controls don't lineup
      // DOC wvw_SetFont( WinNum, cFontFace, nFontHeight, nFontWidth, nFontWeight, nFontQuality )
      nLineSpacing := 0

      // Default font and colour settings.
      wvw_SetFont( , DATAFONTNAME, DATAFONTSIZE + 2, ( DATAFONTSIZE + 2 ) / 2, PROOF_QUALITY )
      //LSColor := ColorToN( "N" ) // TODO
      LSColor := ColorToN( ;
         GetClrBack( ;
         Token( SetColor() ), ",", 1 ) ;
      )

   ENDIF

   // Set linepacing
   wvw_SetLineSpacing( , nLineSpacing )

   // Set linepacing colour
   wvw_SetLSpaceColor( , LSColor )
   wvw_SetPen( PS_SOLID, , LSColor )

   // Remember window type
   AAdd( aWinType, { lGUIWin, nLineSpacing, LSColor } )

RETURN NIL


// Open a new window.
METHOD WOpen( nTop, nLeft, nBottom, nRight, cTitle, lGUIWin, lCentre, nLineSpacing ) CLASS WApp

   LOCAL nWinNum // , LSColor

   // Default to main window's values.
   DEFAULT lGUIWin TO ::lGUIApp
   DEFAULT lCentre TO .F.
   DEFAULT nLineSpacing TO iif( lGUIWin, LINESPACING, 0 )

   // DOC wvw_nOpenWindow( cWinName, row1, col1, row2, col2, nStyle, nParentWin, nExStyle )
   nWinNum := wvw_nOpenWindow( cTitle, nTop, nLeft, nBottom, nRight )

   ::WinSetup( lGUIWin )

   // Set linespacing and linepacing colour.
   wvw_SetLineSpacing( nWinNum, aWinType[ Len( aWinType ), 2 ] )
   wvw_SetLSpaceColor( nWinNum, aWinType[ Len( aWinType ), 3 ] )

   // Initialise window's GUI objects.
   ::WInit( cTitle )

   // Center and display window.
   wvw_SetWindowCentre( nWinNum, lCentre, .T. )

   RETURN nWinNum


// Open a new popup window.
METHOD WPopup( nTop, nLeft, nBottom, nRight, lGUIWin, lCentre, nLineSpacing ) CLASS WApp

   LOCAL nWinNum

   // Default to main window's values.
   DEFAULT lGUIWin TO ::lGUIApp
   DEFAULT lCentre TO .F.
   DEFAULT nLineSpacing TO iif( lGUIWin, LINESPACING, 0 )

   // DOC wvw_nOpenWindow( cWinName, row1, col1, row2, col2, nStyle, nParentWin, nExStyle )
   nWinNum := wvw_nOpenWindow( , nTop, nLeft, nBottom, nRight, WS_POPUPWINDOW )

   ::WinSetup( lGUIWin )

   // Set linespacing and linepacing colour.
   wvw_SetLineSpacing( nWinNum, aWinType[ Len( aWinType ), 2 ] )
   wvw_SetLSpaceColor( nWinNum, aWinType[ Len( aWinType ), 3 ] )

   // Initialise window's GUI objects.
   ::WInit( '' )

   // Center and display window.
   wvw_SetWindowCentre( nWinNum, lCentre, .T. )

   RETURN nWinNum


// Initialise window related GUI objects.
METHOD WInit( cTitle ) CLASS WApp

   IF cTitle <> NIL
      wvw_SetTitle( TOPWINDOW, cTitle )
   ENDIF

   ::WCLS()

   // GET boxes for GetList belonging to this window except
   // for GETs which have visual controls attached to them.
   IF aWinType[ Len( aWinType ), 1 ]
      IF ! WIN10LOOK
         AddGuiObj( , ;
            { || AEval( GetList, { | oGet | iif( Empty( oGet:control ), ;
               wvw_DrawBoxGet( TOPWINDOW, oGet:Row, oGet:Col, Len( Transform( oGet:VarGet(), oGet:PICTURE ) ) ), ;
                  .T. ) } ) } ;
                  )
      ELSE
         AddGuiObj( , ;
            { || AEval( GetList, { | oGet | iif( Empty( oGet:control ), ;
               wvw_DrawBoxGet_XP( TOPWINDOW, oGet:Row, oGet:Col, Len( Transform( oGet:VarGet(), oGet:PICTURE ) ) ), ;
                  .T. ) } ) } ;
                  )
      ENDIF
   ENDIF

   RETURN 0


// Clear window's GUI objects first
// and then clear window.
METHOD WCLS() CLASS WApp

   ClrGuiObjs( TOPWINDOW )
   ClrGuiCtls( TOPWINDOW )
   hb_Scroll()

   GetList := {}

   RETURN 0


// Close top most window.
METHOD WClose() CLASS WApp

   // Clear GUI objects belonging to this window before closing.
   ::WCLS()
   wvw_tbDestroy()
   wvw_lCloseWindow()

   IF Len( aWinType ) > 1
      ASize( aWinType, Len( aWinType ) - 1 )
   ENDIF

   RETURN 0


// *** custom get reader for GUI controls ***
//
// Custom reader for oGet, a GET object hidden beneath a Control.
// oGet:control contains control object:
//

FUNCTION GenReader( oGet, bAction )

   LOCAL nKeyStd, bKeyBlock
   LOCAL oGetList := __GetListActive()

   oGet:control:SetFocus()
   oGet:setfocus()

   nKeyStd := Inkey( 0 )

   DO CASE
   CASE nKeyStd == K_ENTER

      // In WVW_CB_KBD_CLIPPER mode for COMBOBOX we will never get here

      IF HB_ISBLOCK( bAction )
         Eval( bAction )
         oGet:exitState := GE_NOEXIT
      ELSE
         oGet:exitState := GE_DOWN
      ENDIF

      oGet:exitState := GE_DOWN

   CASE nKeyStd == K_UP .OR. nKeyStd == K_LEFT
      IF oGet:control:cClassName == 'RADIOGROUP'
         // Selection within a radio group.
         oGet:control:PrevItem()
         oGet:VarPut( oGet:control:nButton )
         oGet:exitState := GE_NOEXIT
      ELSE
         oGet:exitState := GE_UP
      ENDIF

   CASE nKeyStd == K_SH_TAB
      oGet:exitState := GE_UP

   CASE nKeyStd == K_DOWN .OR. nKeyStd == K_RIGHT

      // In WVW_CB_KBD_STANDARD mode for COMBOBOX we will never get here

      IF oGet:control:cClassName == 'RADIOGROUP'
         // Selection within a radio group.
         oGet:control:NextItem()
         oGet:VarPut( oGet:control:nButton )
         oGet:exitState := GE_NOEXIT
      ELSE
         oGet:exitState := GE_DOWN
      ENDIF

   CASE nKeyStd == K_TAB
      oGet:exitState := GE_DOWN

   CASE nKeyStd == K_ESC
      IF Set( _SET_ESCAPE )
         oGet:exitState := GE_ESCAPE
      ENDIF

   // CASE nKeyStd == K_PGUP
   //    oGet:exitState := GE_WRITE

   // CASE nKeyStd == K_PGDN
   //    oGet:exitState := GE_WRITE

   CASE nKeyStd == K_CTRL_W
      oGet:exitState := GE_WRITE

   CASE nKeyStd == K_CTRL_HOME
      oGet:exitState := GE_TOP

   CASE nKeyStd == K_CTRL_END
      oGet:exitState := GE_BOTTOM

   CASE nKeyStd == K_LBUTTONDOWN
      IF Empty( oGetList:HitTest( MRow(), MCol() ) )
         // No GET object hit.
         oGet:exitState := GE_NOEXIT
      ELSE
         oGet:exitState := GE_MOUSEHIT
      ENDIF

   CASE HB_ISBLOCK( bKeyBlock := SetKey( nKeyStd ) )
      // Evaluate key codeblock.
      // Example: SetKey( K_F7,  { || EBPrint( cText ) } )
      Eval( bKeyBlock )
      oGet:exitState := GE_NOEXIT

   OTHERWISE
      // Ignore all other keystrokes.
      oGet:exitState := GE_NOEXIT

   ENDCASE

   IF oGet:exitState != GE_NOEXIT
      oGet:killfocus()
   ENDIF

   RETURN 0

// WVW Callback functions

// Called after application window is restored or when
// user clicks on a window
FUNCTION wvw_SetFocus( nWinNum )

   LOCAL oGet

   IF nWinNum <> TOPWINDOW
      // Set focus to topmost window
      win_SetFocus( wvw_GetWindowHandle( TOPWINDOW ) )

      // ... and to GET if any.
      // This is needed to ensure GUI control does not lose focus.
      oGet := GetActive()

      IF ! Empty( oGet )
         // IF HB_ISOBJECT( oGet:control ) // TODO
         IF ! Empty( oGet:control )
            // Focus on GUI control
            oGet:control:SetFocus()
         ENDIF
      ENDIF
   ENDIF

   RETURN 0


// This function is called when a window gets WM_PAINT message.
// It receives only nWinNum parameter.
FUNCTION wvw_Paint( nWinNum )

//    IF nWinNum == NIL
//       RETURN 0
//    ENDIF

   DEFAULT nWinNum TO TOPWINDOW

   IF Len( aGuiObjs ) >= nWinNum + 1
      AEval( aGuiObjs[ nWinNum + 1 ], { | e | Eval( e, nWinNum ) } )
   ENDIF

   RETURN 0


FUNCTION wvw_Size( nWinNum, hWnd, message, wParam, lParam )

   HB_SYMBOL_UNUSED( hWnd )
   HB_SYMBOL_UNUSED( message )
   HB_SYMBOL_UNUSED( lParam )

   DEFAULT nWinNum TO TOPWINDOW

   IF ! wvw_Size_Ready()
      RETURN 0
   ENDIF

   IF nWinNum <> 0
      // Only care about the Main Window
      RETURN 0
   ENDIF

   // Avoid re-entry
   wvw_Size_Ready( .F. )

   DO CASE
   CASE wParam == SIZE_MINIMIZED    // 1
      // After wnidow is minimized
   CASE wParam == SIZE_RESTORED     // 0
      // After window is restored
   ENDCASE

   wvw_Size_Ready( .T. )

   RETURN 0


// Functions to manage the repainting of non-native GUI objects.
// GETBOX, LABEL, LABELOBJ, BOX, IMAGE
FUNCTION ClrGuiObjs( nWinNum )

   DEFAULT nWinNum TO TOPWINDOW

   DO WHILE Len( aGuiObjs ) < nWinNum + 1
      // Create one if missing.
      AAdd( aGuiObjs, {} )
   ENDDO

   aGuiObjs[ nWinNum + 1 ] := {}

   RETURN .T.


FUNCTION AddGuiObj( nWinNum, bAction )

   DEFAULT nWinNum TO TOPWINDOW

   // Add codeblock to repaint this control
   AAdd( aGuiObjs[ nWinNum + 1 ], bAction )

   RETURN .T.


FUNCTION LenGuiObjs( nWinNum )

   DEFAULT nWinNum TO TOPWINDOW

   RETURN Len( aGuiObjs[ nWinNum + 1 ] )


FUNCTION ReSizeGuiObjs( nWinNum, aLen )

   DEFAULT nWinNum TO TOPWINDOW

   ASize( aGuiObjs[ nWinNum + 1 ], aLen )

   RETURN 0


// Functions to manage the destruction of persistant native GUI objects.
// CHECKBOX, EDITBOX, LISTBOX, PUSHBUTTON, RADIOGROUP
FUNCTION ClrGuiCtls( nWinNum )

   DEFAULT nWinNum TO TOPWINDOW

   DO WHILE Len( aGUICtls ) < nWinNum + 1
      // Create one if missing.
      AAdd( aGUICtls, {} )
   ENDDO

   // Destroy all controls for this window
   AEval( aGUICtls[ nWinNum + 1 ], { | e | Eval( e ) } )

   aGUICtls[ nWinNum + 1 ] := {}

   RETURN 0


FUNCTION AddGuiCtl( nWinNum, bAction )

   DEFAULT nWinNum TO TOPWINDOW

   // Add action to destroy this control
   AAdd( aGUICtls[ nWinNum + 1 ], bAction )

   RETURN 0


FUNCTION LenGuiCtls( nWinNum )

   DEFAULT nWinNum TO TOPWINDOW

   RETURN Len( aGUICtls[ nWinNum + 1 ] )


/*
FONT Selection

Default font size is based on application type.
   Console  GUI
   16M      15M

Window   Console  GUI
Heading  +3B      +1M
Menu     +4M      n/a
Label    +1M      +0M
Column   -1N      -1N

Report Font Size is 16M

*/

FUNCTION Std_FontSize()

   IF aWinType[ Len( aWinType ), 1 ]
      // GUI window
      IF aWinType[ 1, 1 ]
         // GUI main window
         RETURN LABELFONTSIZE
      ENDIF

   ENDIF

   RETURN LABELFONTSIZE + 1


FUNCTION ReportFont()

   // Any smaller, the reports are unreadable
   RETURN { DATAFONTNAME, 16, FW_MEDIUM }


FUNCTION HeadFont()

   IF aWinType[ Len( aWinType ), 1 ]
      // GUI window
      RETURN { LABELFONTNAME, Std_FontSize() + 2, FW_MEDIUM }
   ENDIF

   RETURN { LABELFONTNAME, Std_FontSize() + 2, FW_BOLD }


FUNCTION MenuFont()

   // For Console style menus drawn using LABELOBJ only.
   RETURN { LABELFONTNAME, Std_FontSize() + 4, FW_MEDIUM }


FUNCTION LabelFont()

   IF aWinType[ Len( aWinType ), 1 ]
      // GUI window
      RETURN { LABELFONTNAME, Std_FontSize(), FW_MEDIUM }
   ENDIF

   RETURN { LABELFONTNAME, Std_FontSize() + 1, FW_MEDIUM }


FUNCTION ColumnFont()

   RETURN { LABELFONTNAME, Std_FontSize() - 1, FW_NORMAL }


FUNCTION SBCreate( aParts )
   LOCAL x

   // Create statusbar and add parts.
   // DOC wvw_sbAddPart( nWinNum, cMaxText, nWidth, nStyle, lResetParts, cIcon, cTooltip )
   wvw_sbCreate()

   FOR x := 1 TO Len( aParts )
      wvw_sbAddPart( 0, Space( aParts[x] ) )
   NEXT x

   wvw_SetWindowCentre( , .F. )

RETURN 0


// Display message in main windows's status bar.
FUNCTION SBSetText( nPartno, cText )

   DEFAULT nPartno TO 0
   DEFAULT cText TO ''

   // Can colour first part only. I think!
   IF Empty( cText )
      // Clear status bar message area
      wvw_sbSetText( 0, nPartno, ( cText ) ) //, GetSysColor( 8 ), GetSysColor( 4 ) )
   ELSE
      // Display status bar message.
      wvw_sbSetText( 0, nPartno, ( cText ) ) //, GetSysColor( 8 ), GetSysColor( 4 ) )
   ENDIF

   WVW_SBRefresh()

   RETURN 0


FUNCTION CreateToolbar( aButtons )

   // Toolbar settings
   LOCAL nSysBitmap := 0     // 0:none 1:small 2:large
   LOCAL lDisplayText := .F. // text will be displayed as tooltip instead
   LOCAL hWndTB

   // DOC WVW_TBCreate( nWinNum, lDisplayText, nStyle, nSystemBitmap, nImageWidth, nImageHeight )
   hWndTB := wvw_tbCreate( , lDisplayText, , nSysBitmap, 24, 24 )

   IF ! Empty( hWndTB )
      AEval( aButtons, {| x | wvw_tbAddButton( , x[ 1 ], x[ 2 ], x[ 3 ] ) } )
   ENDIF

   RETURN 0


FUNCTION DisableMenu( nWinNum, nNumItem )

   // Disables Menu Items of window nWinNum
   LOCAL i
   LOCAL hMenu

   DEFAULT nWinNum TO 0
   DEFAULT nNumItem TO 1

   hMenu := wvw_GetMenu( nWinNum )

   FOR i := 0 TO nNumItem - 1
      wvw_EnableMenuItem( hMenu, i, MF_BYPOSITION + MF_DISABLED )
   NEXT

   wvw_DrawMenuBar( nWinNum )   // to force redraw of menu

   RETURN 0


FUNCTION EnableMenu( nWinNum, nNumItem )

   // Enables Menu Items of window nWinNum
   LOCAL i
   LOCAL hMenu

   DEFAULT nWinNum TO 0
   DEFAULT nNumItem TO 1

   hMenu := wvw_GetMenu( nWinNum )

   FOR i := 0 TO nNumItem - 1
      wvw_EnableMenuItem( hMenu, i, MF_BYPOSITION + MF_ENABLED )
   NEXT

   wvw_DrawMenuBar( nWinNum )   // to force redraw of menu

   RETURN 0


FUNCTION DisableToolbar( nWinNum )

   LOCAL i

   DEFAULT nWinNum TO 0

   FOR i := 0 TO wvw_tbButtonCount( nWinNum ) - 1
      wvw_tbEnableButton( nWinNum, i, .F. )
   NEXT

   RETURN 0


FUNCTION EnableToolbar( nWinNum )

   LOCAL i

   DEFAULT nWinNum TO 0

   FOR i := 0 TO wvw_tbButtonCount( nWinNum ) - 1
      wvw_tbEnableButton( nWinNum, i, .T. )
   NEXT

   RETURN 0


// EOF: WVWCLIPCLASS.PRG

