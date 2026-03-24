-- v0.01 BananaGames (with SAVE + SIGNUP)

local CONFIG = {
    freePackCooldown = 0.9,
    bhpPerSecond = 1,
    accountsFile = "accounts.txt",
    bannerPath = "banners/welcome.txt"
}

local accounts = {}
local username = nil
local displayText = ""
local bannerText = ""
local inputText = ""
local loggedIn = false

-- =========================
-- LOAD / SAVE
-- =========================

local function loadAccounts()
    local contents = lovr.filesystem.read(CONFIG.accountsFile)
    if contents then
        for line in contents:gmatch("[^\r\n]+") do
            local name, bb, bhp = line:match("user %d+: (.+)|(.+)|(.+)")
            if name then
                accounts[name] = {
                    balanceBB = tonumber(bb),
                    balanceBHP = tonumber(bhp),
                    lastFreePack = 0
                }
            end
        end
    end
end

local function saveAllAccounts()
    local data = ""
    local i = 1

    for name, acc in pairs(accounts) do
        data = data .. string.format(
            "user %d: %s|%f|%f\n",
            i, name, acc.balanceBB, acc.balanceBHP
        )
        i = i + 1
    end

    lovr.filesystem.write(CONFIG.accountsFile, data)
end

-- =========================
-- SIGNUP / LOGIN
-- =========================

local function loginOrSignup(name)
    username = name

    if not accounts[name] then
        -- NEW USER (signup)
        accounts[name] = {
            balanceBB = 0,
            balanceBHP = 0,
            lastFreePack = 0
        }
    end

    loggedIn = true
    saveAllAccounts()
end

-- =========================
-- BANNER
-- =========================

local function loadBanner()
    local contents = lovr.filesystem.read(CONFIG.bannerPath)
    bannerText = contents or "=== BANANAGAMES ==="
end

-- =========================
-- GAME SYSTEMS
-- =========================

local function claimFreePack()
    local acc = accounts[username]
    local now = lovr.timer.getTime()

    if now - acc.lastFreePack >= CONFIG.freePackCooldown then
        acc.balanceBB = acc.balanceBB + 1
        acc.lastFreePack = now
        saveAllAccounts()
    end
end

local function accrueBHP(dt)
    local acc = accounts[username]
    acc.balanceBHP = acc.balanceBHP + CONFIG.bhpPerSecond * dt
end

-- =========================
-- DISPLAY
-- =========================

local function updateDisplay()
    if not loggedIn then
        displayText =
            bannerText ..
            "\n\nENTER USERNAME:\n" ..
            inputText
        return
    end

    local acc = accounts[username]

    displayText =
        bannerText ..
        "\n\nUser: " .. username ..
        "\n\nBB: " .. string.format("%.2f", acc.balanceBB) ..
        "\nBHP: " .. string.format("%.2f", acc.balanceBHP) ..
        "\n\n(Press SPACE for free pack)"
end

-- =========================
-- INPUT
-- =========================

function lovr.textinput(t)
    if not loggedIn then
        inputText = inputText .. t
    end
end

function lovr.keypressed(key)
    if not loggedIn then
        if key == "return" then
            if #inputText > 0 then
                loginOrSignup(inputText)
            end
        elseif key == "backspace" then
            inputText = inputText:sub(1, -2)
        end
        return
    end

    if key == "space" then
        claimFreePack()
    end
end

-- =========================
-- LOVR
-- =========================

function lovr.load()
    loadAccounts()
    loadBanner()
end

function lovr.update(dt)
    if loggedIn then
        accrueBHP(dt)
    end
    updateDisplay()
end

function lovr.draw(pass)
    local x, y, z = lovr.headset.getPosition()
    pass:text(displayText, x, y, z - 1.5, 0.25)
end