-- This file is not required in the mod itself, but is read by the language server for type smarts

--- @class CustomObject
--- @field type string
--- @field name string
--- @field remark LocalisedString?

--- @alias GenericObject Ingredient|Product|CustomObject
--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype

--- @class GuiRefs
--- @field window LuaGuiElement
--- @field titlebar_flow LuaGuiElement
--- @field nav_backward_button LuaGuiElement
--- @field nav_forward_button LuaGuiElement
--- @field search_textfield LuaGuiElement
--- @field search_button LuaGuiElement
--- @field show_hidden_button LuaGuiElement
--- @field show_unresearched_button LuaGuiElement
--- @field pin_button LuaGuiElement
--- @field close_button LuaGuiElement
--- @field filter_group_table LuaGuiElement
--- @field filter_scroll_pane LuaGuiElement
--- @field page_scroll LuaGuiElement
--- @field page_header_icon LuaGuiElement
--- @field page_header_label LuaGuiElement
--- @field page_header_type_label LuaGuiElement

--- @alias Object GenericObject|Ingredient|Product
--- @alias ObjectPrototype LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype

--- @class PlayerTable
--- @field gui Gui?

--- @class PrototypeEntry
--- @field recipe LuaRecipePrototype?
--- @field item LuaItemPrototype?
--- @field fluid LuaFluidPrototype?
--- @field entity LuaEntityPrototype?
--- @field researched table<uint, boolean>?

--- Every searchable object sorted by order of appearance.
--- Keyed by object name, using Factorio Lua's insertion order preservation to retain order
--- Value is the object's sorting string
--- @alias SortedObjects table<string, string>
