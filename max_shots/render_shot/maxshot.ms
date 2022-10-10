


savepath = "C:\\render_shots\\" + "shot_.jpg" 
fn create_snapshot save_path = (
    therender = getlastrenderedimage()
    print therender
    if  therender != undefined do (
        setclipboardbitmap therender
        therender.filename = save_path
        save therender
    )
)


fn create_vfb_snapshot save_path = (
    vfbControl #saveimage savepath

)
fn getRendererIdString =
(
    case (renderers.current.classid as string) of
    (
        "#(1, 0)": "scanline"
        "#(1387076610, 288174012)": "brazil"
        "#(95494396, 474502030)": "brmax"
        "#(1492548972, 1338981315)": "mentalray"
        "#(1941615238, 2012806412)": "vray"
        "#(1770671000, 1323107829)": "vrayrt"
        "#(-1204370534, -399920359)": "krakatoa"
        "#(1121714582, 90602926)": "amaretto" 
        "#(217131703, 58075251)": "finalrender"
        "#(272052741, 712862621)": "maxwell"
        "#(268839321, 1854680990)": "quicksilver"
        "#(1048411834, 348141227)": "iray"
        "#(1655201228, 1379677700)": "corona"
        "#(1L, 0L)": "scanline"
        "#(2980329694L, 2688902778L)": "arnold"
        "#(1655201228L, 1379677700L)": "corona"
        "#(95494396L, 474502030L)": "brmax"
        "#(1941615238L, 2012806412L)": "vray"
        "#(1770671000L, 1323107829L)": "vrayrt"
        "#(3090596762L, 3895046937L)": "krakatoa"
        "#(1121714582L, 90602926L)": "amaretto"
        "#(268839321L, 1854680990L)": "quicksilver"
        "#(1048411834L, 348141227L)": "iray"
        "#(2980325325L, 2688898415L)": "art"
        "#(198269858L, 1937796512L)": "redshift"
        "#(33030992L, 1363098752L)": "fstormrender"

        default: undefined
    )
)
 

print (getRendererIdString() as string )
if getRendererIdString() == "vray" then (
    showvfb = vfbControl #show
    if showvfb[1] ==1 then (
        print ("Default Vray Renderer 1")
        rendUseActiveView=true
        create_vfb_snapshot savepath
       )

    else(
        print ("Default Vray Renderer 2 ") 
        rendUseActiveView=true
        create_snapshot savepath
    )
)

if getRendererIdString() == "corona" then (
    print ("Default Corona Renderer ")
    CoronaRenderer.saveAllElements savepath
)


if getRendererIdString() == "scanline" then (
    print ("Default renderer ")
    rendUseActiveView=true
    create_snapshot savepath
)
