-- BookShelfHint v9
-- Creates a separate UTextBlock for the shelf label, leaving the game's original
-- book title and its style untouched. No external Python/overlay process.

local function script_directory()
    local source = debug.getinfo(1, "S").source or ""
    source = source:gsub("^@", ""):gsub("\\", "/")
    return source:match("^(.*)/[^/]+$") or "."
end
local SCRIPT_DIR = script_directory()
local MOD_DIR = SCRIPT_DIR:match("^(.*)/Scripts$") or SCRIPT_DIR
local CATALOG_PATH = MOD_DIR .. "/catalog.txt"
local LOG_PATH = MOD_DIR .. "/BookShelfHint.log"

local function log(message)
    local f = io.open(LOG_PATH, "a")
    if f then f:write(os.date("[%H:%M:%S] "), tostring(message), "\n"); f:close() end
    print("[BookShelfHint] " .. tostring(message) .. "\n")
end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local function normalize(s)
    s = tostring(s or ""):gsub("《", ""):gsub("》", "")
    s = s:gsub("只传于听者的启示", "只传于听者的指示")
    s = s:gsub("将食物转化为成屎的炼金艺术", "将食物转化为屎的炼金艺术")
    s = s:gsub("咖哩", "咖喱"):gsub("[Vv][Ss]", "vs")
    s = s:gsub("[Vv][Oo][Ll][Uu][Mm][Ee]%.?%s*%d+", "")
    s = s:gsub("[Vv][Oo][Ll]%.?%s*%d+", "")
    s = s:gsub("第%s*%d+%s*卷", ""):gsub("第%s*%d+%s*册", "")
    s = s:gsub("·", ""):gsub("・", "")
    s = s:gsub("：", ":"):gsub("－", "-"):gsub("—", "-"):gsub("–", "-")
    s = s:gsub("%s+", "")
    return trim(s)
end

local book_to_shelf, shelf_names, current_shelf = {}, {}, nil
local cf = io.open(CATALOG_PATH, "r")
if not cf then log("错误：无法打开目录文件：" .. CATALOG_PATH) else
    for raw in cf:lines() do
        local line = trim(raw)
        local code, name = line:match("^([12][A-Q]):(.+)$")
        if not code then code, name = line:match("^([12][A-Q])：(.+)$") end
        if code then current_shelf = code; shelf_names[code] = trim(name)
        else
            local title = line:match("^《(.+)》$")
            if title and current_shelf then book_to_shelf[normalize(title)] = current_shelf end
        end
    end
    cf:close()
end

local function match_book(text)
    local n = normalize(text)
    if n == "" then return nil end
    local code = book_to_shelf[n]
    if code then return code, shelf_names[code] end
    local best_code, best_len = nil, 0
    for title, shelf in pairs(book_to_shelf) do
        if #title >= 9 and #title > best_len and n:find(title, 1, true) then
            best_code, best_len = shelf, #title
        end
    end
    if best_code then return best_code, shelf_names[best_code] end
end

local function valid(obj)
    if not obj then return false end
    local ok, result = pcall(function() return obj:IsValid() end)
    return ok and result == true
end
local function color_for(code)
    if tostring(code):sub(1,1) == "1" then
        return { R=1.0, G=105/255, B=180/255, A=1.0 }
    end
    return { R=0.0, G=191/255, B=1.0, A=1.0 }
end
local function style_hint(w, code, match_font_size)
    pcall(function()
        local font = w.Font
        -- The held-book hint must use exactly the same font size as its original title.
        if match_font_size and match_font_size > 0 then font.Size = match_font_size end
        local outline = font.OutlineSettings
        outline.OutlineSize = 2
        outline.OutlineColor = color_for(code)
        font.OutlineSettings = outline
        w:SetFont(font)
        w:SetColorAndOpacity({SpecifiedColor={R=1.0,G=1.0,B=1.0,A=1.0}, ColorUseRule=0})
    end)
end

local function get_font_size(widget)
    local size = nil
    pcall(function() size = widget.Font.Size end)
    if type(size) == "number" and size > 0 then return size end
    return nil
end

-- Remove any hint appended by earlier versions or by a previous SetText callback.
local function strip_old_hint(text)
    text = tostring(text or "")
    text = text:gsub("%s*→%s*[12][A-Q]：[^\r\n]*", "")
    return trim(text)
end

local hint_widgets = {}
local textblock_class
pcall(function() textblock_class = StaticFindObject("/Script/UMG.TextBlock") end)

local function place_hint(original, hint_widget, is_target, is_new)
    local parent = original:GetParent()
    if not valid(parent) then return false, "原控件没有有效 Parent" end
    local parent_name = parent:GetFullName()
    local slot = nil
    if is_new then
        local added_slot = parent:AddChild(hint_widget)
        if not added_slot then return false, "Parent:AddChild 未返回 Slot；Parent=" .. parent_name end
        slot = added_slot
    else
        pcall(function() slot = hint_widget.Slot end)
        if not slot then return false, "已有提示控件没有有效 Slot；Parent=" .. parent_name end
    end

    local is_canvas = parent_name:find("CanvasPanel", 1, true) ~= nil
    if is_canvas then
        local original_slot
        pcall(function() original_slot = original.Slot end)
        if not original_slot then return false, "CanvasPanel 中找不到原书名 Slot" end
        local ok, err = pcall(function()
            local pos = original_slot:GetPosition()
            local original_anchors = original_slot:GetAnchors()
            local original_alignment = original_slot:GetAlignment()
            local y_offset = 30
            local original_height = nil

            -- Use the actual arranged geometry / slot size for vertical placement.
            -- Do not use desired width for centering: TextBlock desired size may only
            -- reflect the text's intrinsic width and varies greatly by title length.
            pcall(function()
                local geometry = original:GetCachedGeometry()
                local size = geometry:GetLocalSize()
                if size and size.Y and size.Y > 0 then original_height = size.Y end
            end)
            pcall(function()
                local size = original_slot:GetSize()
                if size and size.Y and size.Y > 0 then original_height = original_height or size.Y end
            end)
            if original_height and original_height > 0 then y_offset = original_height + 4 end

            slot:SetAutoSize(true)
            if is_target then
                -- Place the aiming hint at the horizontal center of the whole
                -- CanvasPanel. This avoids text-width estimates and stale DesiredSize,
                -- both of which caused title-length-dependent left offsets in v8.
                -- Preserve the original vertical anchors, but use a single center X anchor.
                local anchors = {
                    Minimum = { X = 0.5, Y = original_anchors.Minimum.Y },
                    Maximum = { X = 0.5, Y = original_anchors.Maximum.Y }
                }
                slot:SetAnchors(anchors)
                slot:SetAlignment({ X = 0.5, Y = 0.0 })
                local original_align_y = 0.0
                pcall(function() original_align_y = original_alignment.Y end)
                local below_y = pos.Y + y_offset
                if original_height and original_height > 0 then
                    -- The new hint is top-aligned; compute the old title's bottom edge
                    -- even when the original slot uses a non-zero vertical alignment.
                    below_y = pos.Y + original_height * (1.0 - original_align_y) + 4
                end
                slot:SetPosition({ X = 0.0, Y = below_y })
            else
                -- Held-book label remains on the same line to the right of its title.
                pcall(function() slot:SetAnchors(original_anchors) end)
                pcall(function() slot:SetAlignment(original_alignment) end)
                local font_size = 18
                pcall(function() font_size = original.Font.Size end)
                local title_text = ""
                pcall(function() title_text = original:GetText():ToString() end)
                local x_offset = math.max(100, #tostring(title_text) * font_size * 0.55)
                slot:SetPosition({ X = pos.X + x_offset, Y = pos.Y })
            end
        end)
        if not ok then return false, "CanvasPanel 位置设置失败：" .. tostring(err) end
    end
    local slot_name = ""
    pcall(function() slot_name = slot:GetFullName() end)
    return true, parent_name .. (slot_name ~= "" and ("; slot=" .. slot_name) or "")
end

local function ensure_hint_widget(original, widget_key, label, code, title_text, is_target)
    local hint_font_size = nil
    if not is_target then hint_font_size = get_font_size(original) end
    local hint = hint_widgets[widget_key]
    if valid(hint) then
        local ok, err = pcall(function()
            hint:SetText(FText(label))
            style_hint(hint, code, hint_font_size)
            hint:SetVisibility(0)
        end)
        if not ok then return false, "更新已有提示失败：" .. tostring(err) end
        local placed, detail = place_hint(original, hint, is_target, false)
        if not placed then return false, detail end
        return true
    end
    if not textblock_class then
        log("无法找到 /Script/UMG.TextBlock 类，不能创建独立提示控件")
        return false
    end
    local parent = original:GetParent()
    if not valid(parent) then log("无法创建提示：原书名控件没有有效 Parent"); return false end
    local ok, created = pcall(function() return StaticConstructObject(textblock_class, parent) end)
    if not ok or not valid(created) then
        log("StaticConstructObject 创建独立 TextBlock 失败：" .. tostring(created))
        return false
    end
    local setok, seterr = pcall(function()
        created:SetText(FText(label))
        created:SetVisibility(0)
        style_hint(created, code, hint_font_size)
    end)
    if not setok then log("初始化独立提示控件失败：" .. tostring(seterr)); return false end
    local addok, layout = place_hint(original, created, is_target, true)
    if not addok then
        log("独立提示控件未能加入/定位原 UI：" .. tostring(layout))
        return false
    end
    hint_widgets[widget_key] = created
    log("已创建独立提示 TextBlock；原书名样式不变。Parent=" .. tostring(layout))
    return true
end

local processing = false
local logged = {}
local function log_once(key, msg) if not logged[key] then logged[key] = true; log(msg) end end
local function on_set_text_post(context, input_text)
    if processing then return end
    local ok, err = pcall(function()
        local original = context:get()
        if not valid(original) then return end
        local name = original:GetFullName()
        local is_book_row = name:match("Text_BookName$") ~= nil
        local is_target = name:match("Text_LookingItem$") ~= nil
        if not is_book_row and not is_target then return end
        local text_obj = input_text:get()
        local raw_text = ""
        if text_obj and text_obj.ToString then raw_text = text_obj:ToString() end
        raw_text = raw_text:gsub("[\r\n\t]", " ")
        local text = strip_old_hint(raw_text)

        -- Remove a suffix left behind by v4/v5 directly from the original widget,
        -- while preserving its existing font/style. Guard the SetText hook recursion.
        if text ~= trim(raw_text) then
            processing = true
            pcall(function() original:SetText(FText(text)) end)
            processing = false
        end
        if text == "" then
            local parent = original:GetParent()
            local parent_name = valid(parent) and parent:GetFullName() or name
            local key = (is_target and "target|" or "held|") .. parent_name
            local old = hint_widgets[key]
            if valid(old) then pcall(function() old:SetText(FText("")); old:SetVisibility(1) end) end
            return
        end
        local code, shelf_name = match_book(text)
        if not code or not shelf_name then return end
        -- No arrow on the aiming hint; keep it on the same line as the held title.
        local label = is_target and (code .. "：" .. shelf_name) or ("→ " .. code .. "：" .. shelf_name)
        local parent = original:GetParent()
        local parent_name = valid(parent) and parent:GetFullName() or name
        -- One label per visual row/panel prevents duplicates from multiple TextBlocks.
        local widget_key = (is_target and "target|" or "held|") .. parent_name
        processing = true
        local displayed, why = ensure_hint_widget(original, widget_key, label, code, text, is_target)
        processing = false
        if displayed then
            log_once(widget_key .. "|" .. normalize(text), (is_book_row and "手持书名行" or "瞄准目标") .. "提示已更新：" .. text .. " => " .. label)
        else
            log_once("createfail|" .. widget_key, "独立提示创建/布局失败：" .. tostring(why or "请查看前面的错误日志"))
        end
    end)
    processing = false
    if not ok then log("处理 SetText POST-hook 时出错：" .. tostring(err)) end
end

local ok, err = pcall(function()
    RegisterHook("/Script/UMG.TextBlock:SetText", function() end, on_set_text_post)
end)
local books, shelves = 0, 0
for _ in pairs(book_to_shelf) do books = books + 1 end
for _ in pairs(shelf_names) do shelves = shelves + 1 end
if ok then log(string.format("v9 已启动；目录载入 %d 个书名、%d 个书架。", books, shelves))
else log("注册 TextBlock:SetText POST-hook 失败：" .. tostring(err)) end
