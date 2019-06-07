(*
    Copyright 2018 Fernando Borretti <fernando@borretti.me>

    This file is part of Austral.

    Austral is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Austral is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Austral.  If not, see <http://www.gnu.org/licenses/>.
*)

structure Macro :> MACRO = struct
    datatype match = Match of match_exp list * match_rest
         and match_exp = MatchVariable of Symbol.symbol
                       | MatchKeyword of Symbol.symbol_name
                       | MatchList of match_exp list * match_rest
         and match_rest = MatchRest
                        | MatchFixed

    datatype template_exp = TemplateExp of RCST.rcst

    datatype template_case = TemplateCase of match * template_exp

    datatype template = Template of Symbol.symbol * string option * template_case list

    datatype symbol_macro = SymbolMacro of Symbol.symbol * RCST.rcst * string option

    fun symbolMacroName (SymbolMacro (name, _, _)) = name
    fun symbolMacroExpansion (SymbolMacro (_, exp, _)) = exp

    type template_map = (Symbol.symbol, template) Map.map
    type symbol_macro_map = (Symbol.symbol, symbol_macro) Map.map

    datatype macroenv = MacroEnv of template_map * symbol_macro_map

    val emptyMacroEnv = MacroEnv (Map.empty, Map.empty)

    fun getSymbolMacro (MacroEnv (_, mm)) s =
        Map.get mm s

    fun addSymbolMacro (MacroEnv (t, sm)) mac =
        (case Map.add sm (symbolMacroName mac, mac) of
             SOME sm' => SOME (MacroEnv (t, sm'))
           | NONE => NONE)

    (* Macroexpansion *)

    local
        open RCST
    in
        fun macroexpandSymbolMacros env form =
            let fun expand (Symbol s) =
                    (case (getSymbolMacro env s) of
                         SOME mac => symbolMacroExpansion mac
                       | NONE => (Symbol s))
                  | expand (Keyword s) = Keyword s
                  | expand (Splice exp) = Splice (expand exp)
                  | expand (List l) = List (map expand l)
                  | expand exp = exp
            in
                expand form
            end
    end
end