local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

local Window = Library:CreateWindow({
    Title = "Mouse Hub",
	Size = UDim2.fromOffset(300, 300),
	Icon = "rbxassetid://70948777537440",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true
})

Library.ShowCustomCursor = false

local MainTab = Window:AddTab({
    Name = "Main",
    Icon = "box"
})

Library:AddDraggableButton("Unload UI", function()
    Library:Unload()
end)

local FarmSection= MainTab:AddLeftGroupbox("Farm", "box")
local RestaurantSection = MainTab:AddRightGroupbox("Restaurant", "store")

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local AutocookRunning = false
local AutocookThread

local InstantcookRunning = false
local InstantcookThread

local function getTycoon()
    for _, v in pairs(workspace.Tycoons:GetChildren()) do
        if v:FindFirstChild("Player") and v.Player.Value == lp then
            return v
        end
    end
end

local function runAutoCook()
    if AutocookThread then return end
    AutocookThread = task.spawn(function()
        while AutocookRunning do
            while not getTycoon() do
                task.wait(0.5)
            end

            local tcn = getTycoon()

            local kitchen = tcn:FindFirstChild("Items")
                and tcn.Items:FindFirstChild("OftenFiltered")
                and tcn.Items.OftenFiltered:FindFirstChild("Kitchen")

            if kitchen then
                local function checkModel(model)
                    if not model:IsA("Model") then return end
                    for _, part in ipairs(model:GetDescendants()) do
                        if (part:IsA("Part") or part:IsA("MeshPart")) and part.Name == "Base" then
                            local att = part:FindFirstChild("Attachment")
                            if att then
                                for _, obj in pairs(att:GetChildren()) do
                                    if obj:IsA("ProximityPrompt") then
                                        fireproximityprompt(obj, 1)
                                    end
                                end
                            end
                            local counter = part:FindFirstChild("CounterTop")
                            if counter then
                                local prompt = counter:FindFirstChildWhichIsA("ProximityPrompt")
                                if prompt then
                                    fireproximityprompt(prompt, 1)
                                end
                            end
                        end
                    end
                end

                for _, model in pairs(kitchen:GetChildren()) do
                    checkModel(model)
                end

                kitchen.ChildAdded:Connect(function(child)
                    checkModel(child)
                end)
            end

            local tempFolder = workspace:FindFirstChild("Temp")
            if tempFolder then
                for _, part in ipairs(tempFolder:GetChildren()) do
                    if part:IsA("BasePart") and part.Name == "Part" then
                        local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                        if prompt and (prompt.ActionText == "Cook" or prompt.ActionText == "cook") then
                            fireproximityprompt(prompt, 0)
                        end
                    end
                end
            end

            task.wait(0.1)
        end
        AutocookThread = nil
    end)
end

local function runInstantCook()
    if InstantcookThread then return end
    InstantcookThread = task.spawn(function()
        local player = lp
        local cookingScript = player:WaitForChild("PlayerScripts"):WaitForChild("CookingNew")
        local CookProgress = require(cookingScript:WaitForChild("CookProgress"))
        local MultiClick = require(cookingScript.InputDetectors:WaitForChild("MultiClick"))
        local MouseMovement = require(cookingScript.InputDetectors:WaitForChild("MouseMovement"))
        local MouseSpin = require(cookingScript.InputDetectors:WaitForChild("MouseSpin"))

        local originalRun = CookProgress.run
        local originalMultiClick = MultiClick.start
        local originalMouseMove = MouseMovement.start
        local originalMouseSpin = MouseSpin.start
        local patched = false

        while InstantcookRunning do
            task.wait(0.05)
            if not patched then
                CookProgress.run = function(...) local a = {...} a[3] = 0 return originalRun(unpack(a)) end
                MultiClick.start = function(...) local a = {...} if typeof(a[3]) == "function" then a[3]() end end
                MouseMovement.start = function(...) local a = {...} if typeof(a[3]) == "function" then a[3]() end end
                MouseSpin.start = function(...) local a = {...} if typeof(a[3]) == "function" then a[3]() end end
                patched = true
            end
        end

        CookProgress.run = originalRun
        MultiClick.start = originalMultiClick
        MouseMovement.start = originalMouseMove
        MouseSpin.start = originalMouseSpin
        patched = false
        InstantcookThread = nil
    end)
end

lp.CharacterAdded:Connect(function()
    if AutocookRunning then
        task.wait(3)
        runAutoCook()
    end
    if InstantcookRunning then
        task.wait(3)
        runInstantCook()
    end
end)

local Autocooktoggle = FarmSection:AddToggle("MyToggle", {
    Text = "Auto cook",
    Default = false,
    Tooltip = "Automatically cooks food, good when has Instant cook on.",
    Callback = function(Value)
        AutocookRunning = Value
        if AutocookRunning then
            runAutoCook()
        else
            AutocookThread = nil
        end
    end
})

local Instantcooktoggle = FarmSection:AddToggle("MyToggle", {
    Text = "Instant cook",
    Default = false,
    Tooltip = "instantly cooks food, good when has Auto cook on.",
    Callback = function(Value)
        InstantcookRunning = Value
        if InstantcookRunning then
            runInstantCook()
        else
            InstantcookThread = nil
        end
    end,
}, "INDEX")

local Autocollectcash = RestaurantSection:AddToggle("MyToggle", {
    Text = "Auto collect cash",
    Default = false,
    Tooltip = "Automatically collects cash",
    Callback = function(Value)
        AutocollectRunning = Value

        if AutocollectRunning and not AutocollectThread then
            AutocollectThread = task.spawn(function()
                local lp = game:GetService("Players").LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                local event = rs:WaitForChild("Events"):WaitForChild("ClientTycoonInput")

                while AutocollectRunning do
                    task.wait(0.5)

                    local tcn, surface
                    for _, v in pairs(workspace.Tycoons:GetChildren()) do
                        if v:FindFirstChild("Player") and v.Player.Value == lp then
                            tcn = v
                            local items = v:FindFirstChild("Items")
                            if items and items:FindFirstChild("OftenFiltered") then
                                surface = items.OftenFiltered:FindFirstChild("Surface")
                            end
                            break
                        end
                    end

                    if surface then
                        for _, model in pairs(surface:GetChildren()) do
                            event:FireServer(tcn, { name = "CollectBill", model = model })
                        end
                    end
                end

                AutocollectThread = nil
            end)
        elseif not AutocollectRunning and AutocollectThread then
            AutocollectThread = nil
        end
    end,
})

local AutocollectRunning = false
local AutocollectThread

local AutoseatRunning = false
local AutoseatThread

local Autoseat = RestaurantSection:AddToggle("MyToggle", {
    Text = "Auto seat Customers",
    Default = false,
    Tooltip = "Automatically seats customers",
    Callback = function(Value)
        AutoseatRunning = Value

        if AutoseatRunning and not AutoseatThread then
            AutoseatThread = task.spawn(function()
                local lp = game:GetService("Players").LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                local event = rs:WaitForChild("Events"):WaitForChild("ClientTycoonInput")

                local tcn
                for _, v in pairs(workspace.Tycoons:GetChildren()) do
                    if v:FindFirstChild("Player") and v.Player.Value == lp then
                        tcn = v
                        break
                    end
                end

                if not tcn then 
                    AutoseatRunning = false
                    AutoseatThread = nil
                    return 
                end

                local surface = tcn:WaitForChild("Items"):WaitForChild("OftenFiltered"):WaitForChild("Surface")
                local customersFolder = tcn:WaitForChild("Customers")
                local groupsFolder = tcn:WaitForChild("Items"):WaitForChild("AlwaysFiltered"):WaitForChild("NPCs"):WaitForChild("ClientCustomers")

                while AutoseatRunning do
                    task.wait(0.5)

                    local tables = surface:GetChildren()
                    local customers = customersFolder:GetChildren()
                    local groups = groupsFolder:GetChildren()

                    for _, tableModel in ipairs(tables) do
                        if tableModel:IsA("Model") then
                            for _, customer in ipairs(customers) do
                                for _, group in ipairs(groups) do
                                    event:FireServer(tcn, {
                                        name = "SendToTable",
                                        obj = tableModel,
                                        group = group.Name,
                                        tycoon = tcn,
                                        customer = customer.Name
                                    })
                                end
                            end
                        end
                    end
                end

                AutoseatThread = nil
            end)
        elseif not AutoseatRunning then
            AutoseatThread = nil
        end
    end
})

local AutotakeOrdersRunning = false
local AutotakeOrdersThread

local Autotakeorders = RestaurantSection:AddToggle("MyToggle", {
    Text = "Auto take orders",
    Default = false,
    Tooltip = "Automatically takes orders from customers",
    Callback = function(Value)
        AutotakeOrdersRunning = Value

        if AutotakeOrdersRunning and not AutotakeOrdersThread then
            AutotakeOrdersThread = task.spawn(function()
                local Players = game:GetService("Players")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local lp = Players.LocalPlayer
                local tycoons = workspace:WaitForChild("Tycoons")
                local event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("ClientTycoonInput")

                local myTycoon
                for _, tycoon in ipairs(tycoons:GetChildren()) do
                    if tycoon:FindFirstChild("Player") and tycoon.Player.Value == lp then
                        myTycoon = tycoon
                        break
                    end
                end

                if not myTycoon then
                    AutotakeOrdersRunning = false
                    AutotakeOrdersThread = nil
                    return
                end

                local clientCustomersFolder = myTycoon:WaitForChild("Items"):WaitForChild("AlwaysFiltered"):WaitForChild("NPCs"):WaitForChild("ClientCustomers")

                while AutotakeOrdersRunning do
                    task.wait(0.1)

                    for _, groupFolder in ipairs(clientCustomersFolder:GetChildren()) do
                        if groupFolder:IsA("Folder") then
                            local groupName = groupFolder.Name

                            for _, customerModel in ipairs(groupFolder:GetChildren()) do
                                if customerModel:IsA("Model") then
                                    local customerName = customerModel.Name

                                    event:FireServer(myTycoon, {
                                        customer = customerName,
                                        tycoon = myTycoon,
                                        name = "ManageCustomers",
                                        group = groupName
                                    })
                                end
                            end
                        end
                    end
                end

                AutotakeOrdersThread = nil
            end)
        elseif not AutotakeOrdersRunning then
            AutotakeOrdersThread = nil
        end
    end
})

local AutocollectDishesRunning = false
local AutocollectDishesThread

local Autocollectdishes = RestaurantSection:AddToggle("MyToggle", {
    Text = "Auto collect dishes",
    Default = false,
    Tooltip = "Automatically collects dishes from tables",
    Callback = function(Value)
        AutocollectDishesRunning = Value

        if AutocollectDishesRunning and not AutocollectDishesThread then
            AutocollectDishesThread = task.spawn(function()
                local lp = game:GetService("Players").LocalPlayer
                local rs = game:GetService("ReplicatedStorage")
                local event = rs:WaitForChild("Events"):WaitForChild("ClientTycoonInput")

                local tcn
                for _, v in pairs(workspace:WaitForChild("Tycoons"):GetChildren()) do
                    if v:FindFirstChild("Player") and v.Player.Value == lp then
                        tcn = v
                        break
                    end
                end

                if not tcn then
                    AutocollectDishesRunning = false
                    AutocollectDishesThread = nil
                    return
                end

                local surface = tcn:WaitForChild("Items"):WaitForChild("OftenFiltered"):WaitForChild("Surface")

                while AutocollectDishesRunning do
                    task.wait(0.1)

                    for _, model in ipairs(surface:GetChildren()) do
                        event:FireServer(tcn, {
                            name = "ClearTrash",
                            model = model
                        })
                    end
                end

                AutocollectDishesThread = nil
            end)
        elseif not AutocollectDishesRunning and AutocollectDishesThread then
            AutocollectDishesThread = nil
        end
    end,
})