local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node

-- Función auxiliar para obtener el nombre del archivo sin extensión
local function get_filename()
    return vim.fn.expand("%:t:r")
end

-- Función auxiliar para generar el Include Guard en mayúsculas
local function get_include_guard()
    return string.upper(get_filename()) .. "_HPP"
end

ls.add_snippets("cpp", {
    s("occf", {
        t("#ifndef "), f(get_include_guard, {}),
        t({"", "# define "}), f(get_include_guard, {}),
        t({"", "", "# include <iostream>", "", "class "}), f(get_filename, {}),
        t({" {", " private:", "\t", " public:", "\t"}),
        
        -- 1. Constructor por defecto
        f(get_filename, {}), t({"(void);", "\t"}), 
        
        -- 2. Constructor de copia
        f(get_filename, {}), t({"(const "}), f(get_filename, {}), t({"& obj);", "\t"}), 
        
        -- 3. Operador de asignación
        f(get_filename, {}), t({"& operator=(const "}), f(get_filename, {}), t({"& obj);", "\t"}), 
        
        -- 4. Destructor (Virtual por seguridad en polimorfismo)
        t({"~"}), f(get_filename, {}), t({"(void);", "};", "", "#endif"}),
    })
})
