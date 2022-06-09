cFortMercerMapMod = class()

function cFortMercerMapMod:__init()

    Citizen.InvokeNative(0xE8770EE02AEE45C2, 1)

end

function cFortMercerMapMod:Unload()
    Citizen.InvokeNative(0xE8770EE02AEE45C2, 0)
end
