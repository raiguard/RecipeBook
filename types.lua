--- @meta
--- This file is not required in the mod itself, but is read by the language server for type smarts

--- @class CustomObject
--- @field type string
--- @field name string
--- @field duration number?

--- @alias EntryProperties table<string, GenericObject[]>

--- @alias GenericObject Ingredient|Product|CustomObject
--- @alias GenericPrototype LuaEntityPrototype|LuaFluidPrototype|LuaItemPrototype|LuaRecipePrototype

--- @class PlayerTable
--- @field gui Gui?
--- @field search_strings table<string, string>?

--- @class PrototypeEntry
--- @field base GenericPrototype
--- @field base_path string
--- @field recipe LuaRecipePrototype?
--- @field item LuaItemPrototype?
--- @field fluid LuaFluidPrototype?
--- @field entity LuaEntityPrototype?
--- @field researched table<uint, boolean>?
