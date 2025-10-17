surface.CreateFont("BroadcastFont", {
    font = "Cambria",
    size = 20,
    weight = 800,
    antialias = true,
    shadow = true,
    italic = true,
})

surface.CreateFont("ixChatFont", {
    font = "Roboto",
    size = math.max(ScreenScale(7), 17) * ix.option.Get("chatFontScale", 1),
    extended = true,
    weight = 600,
    antialias = true
})

surface.CreateFont("ixWhisperChatFont", {
    font = "Roboto",
    size = math.max(ScreenScale(7), 17) * ix.option.Get("chatFontScale", 1) - 4,
    extended = true,
    weight = 600,
    antialias = true
})

surface.CreateFont("ixYellChatFont", {
    font = "Roboto",
    size = math.max(ScreenScale(7), 17) * ix.option.Get("chatFontScale", 1) + 4,
    extended = true,
    weight = 600,
    antialias = true
})

for i = 10, 80 do
    surface.CreateFont("Font-Elements"..tostring(i), {
        font = "Arial",
        size = i,
        weight = 800,
        italic = false,
        antialias = true,
        shadow = false,
    })

    surface.CreateFont("Font-Elements"..tostring(i).."-Shadow", {
        font = "Arial",
        size = i,
        weight = 800,
        italic = false,
        antialias = true,
        shadow = true,
    })

    surface.CreateFont("Font-Elements"..tostring(i).."-Italic", {
        font = "Arial",
        size = i,
        weight = 800,
        italic = true,
        antialias = true,
        shadow = false,
    })

    surface.CreateFont("Font-Elements"..tostring(i).."-Light", {
        font = "Arial",
        size = i,
        weight = 100,
        italic = false,
        antialias = true,
        shadow = false,
    })
end

for i = 10, 80 do
    surface.CreateFont("OpenSans"..tostring(i), {
        font = "Open Sans",
        size = i,
        weight = 800,
        extended = true,
        antialias = true
    })

    surface.CreateFont("OpenSans"..tostring(i).."-Bold", {
        font = "Open Sans",
        size = i,
        weight = 1000,
        extended = true,
        antialias = true
    })
end

for i = 10, 80 do
    surface.CreateFont("OpenSansLight"..tostring(i), {
        font = "Open Sans Light",
        size = i,
        weight = 800,
        extended = true,
        antialias = true
    })

    surface.CreateFont("OpenSansLight"..tostring(i).."-Bold", {
        font = "Open Sans Light",
        size = i,
        weight = 1000,
        extended = true,
        antialias = true
    })
end

for i = 10, 80 do
    surface.CreateFont("CursiveFont"..tostring(i), {
        font = "Great Vibes",
        size = i,
        weight = 800,
        extended = true,
        antialias = true
    })

    surface.CreateFont("CursiveFont"..tostring(i).."-Bold", {
        font = "Great Vibes",
        size = i,
        weight = 1000,
        extended = true,
        antialias = true
    })
end

surface.CreateFont("CursiveFont", {
    font = "Great Vibes",
    size = 18,
    weight = 500,
    extended = true,
})

surface.CreateFont("CursiveFontBold", {
    font = "Great Vibes",
    size = 22,
    weight = 700,
    extended = true,
    antialias = true
})

for i = 10, 80 do
    surface.CreateFont("VintageFont"..tostring(i), {
        font = "Special Elite",
        size = i,
        weight = 800,
        extended = true,
        antialias = true
    })

    surface.CreateFont("VintageFont"..tostring(i).."-Bold", {
        font = "Special Elite",
        size = i,
        weight = 1000,
        extended = true,
        antialias = true
    })
end

surface.CreateFont("VintageFont", {
    font = "Special Elite",
    size = 18,
    weight = 500,
    extended = true,
    antialias = true
})

surface.CreateFont("VintageFontBold", {
    font = "Special Elite",
    size = 20,
    weight = 700,
    extended = true,
    antialias = true
})

--[[ Business Items Fonts ]]--
surface.CreateFont("BusPlayInputFont", {
    font = "Special Elite",
    size = 17,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("BusPromptFont", {
    font = "Special Elite",
    size = 18,
    weight = 700,
    extended = true,
    antialias = true
})
--[[ END ]]--

--[[ Business Items Fonts ]]--
surface.CreateFont("ItemNameFont", {
    font = "Special Elite",
    size = 17,
    weight = 700,
    extended = true,
    antialias = true
})

surface.CreateFont("ItemPriceFont", {
    font = "Special Elite",
    size = 18,
    weight = 700,
    extended = true,
    antialias = true
})
--[[ END ]]--

--[[ Font Awesome ]]--
surface.CreateFont("MaterialDesignIconsDesktop", {
    font = "Material Design Icons Desktop",
    size = 32,
    weight = 500,
    antialias = true
})
--[[ END ]]--