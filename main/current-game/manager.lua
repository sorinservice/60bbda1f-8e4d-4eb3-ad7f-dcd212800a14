-- current-game/manager.lua
print("Welcome Home")
return {
    byPlace = {
        [7711635737] = {  -- Emergency Hamburg PlaceId
            name   = "Emergency Hamburg",
            module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/EmergencyHamburg.lua",
        },


        -[5829141886] = { -- RealisticCarDriving PlaceID
             name   = "RealisticCarDriving",
             module = "https://raw.githubusercontent.com/sorinservice/60bbda1f-8e4d-4eb3-ad7f-dcd212800a14/main/main/current-game/games/RealisticCarDriving.lua",
         },
    },
}
