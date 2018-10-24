(*
    Copyright 2018 Fernando Borretti <fernando@borretti.me>

    This file is part of Boreal.

    Boreal is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Boreal is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Boreal.  If not, see <http://www.gnu.org/licenses/>.
*)

structure Alpha :> ALPHA = struct
    type symbol = Symbol.symbol
    type variable = Symbol.variable
    type typespec = Type.typespec
    type name = symbol

    (* AST *)

    datatype ast = UnitConstant
                 | BoolConstant of bool
                 | IntConstant of string
                 | FloatConstant of string
                 | StringConstant of CST.escaped_string
                 | Variable of variable
                 | Let of variable * ast * ast
                 | The of typespec * ast
                 | Construct of typespec * name * ast option
                 | ForeignFuncall of string * typespec * ast list
                 | ForeignNull of typespec
                 | SizeOf of typespec
                 | Operation of symbol * ast list

    (* Toplevel AST *)
    type docstring = string option
    type param_name = symbol

    datatype top_ast = Defun of name * param list * typespec * docstring * ast
                     | Defgeneric of name * param_name list * param list * typespec * docstring * ast
                     | Defclass of name * param_name * docstring * method_decl list
                     | Definstance of name * instance_arg * docstring * method_def list
                     | Deftype of name * param_name list * docstring * typespec
                     | Defdisjunction of name * param_name list * docstring * variant list
                     | Deftemplate of Macro.template
                     | DefineSymbolMacro of name * RCST.rcst * docstring
                     | Defmodule of Symbol.module_name * Module.defmodule_clause list
                     | InModule of Symbol.symbol_name
         and param = Param of variable * typespec
         and method_decl = MethodDecl of name * param list * typespec * docstring
         and method_def = MethodDef of name * param list * typespec * docstring * ast
         and instance_arg = InstanceArg of name * name list
         and variant = Variant of name * typespec option

    (* Fresh variables *)

    val count = ref 0

    fun freshVar sym =
        let
        in
            count := !count + 1;
            Symbol.Var (sym, !count)
        end

    fun resetCount () =
        count := 0

    (* The stack *)

    type stack = (Symbol.symbol * Symbol.variable) list

    fun lookup ((n,v)::xs) s = if (n = s) then
                                   v
                               else
                                   lookup xs s
      | lookup nil s = raise Fail ("Alpha renaming: no such variable: '"
                                   ^ (Ident.identString (Symbol.symbolName s))
                                   ^ "'")

    (* Alpha renaming *)

    fun alphaRename _ OAST.UnitConstant =
        UnitConstant
      | alphaRename _ (OAST.BoolConstant b) =
        BoolConstant b
      | alphaRename _ (OAST.IntConstant s) =
        IntConstant s
      | alphaRename _ (OAST.FloatConstant f) =
        FloatConstant f
      | alphaRename _ (OAST.StringConstant s) =
        StringConstant s
      | alphaRename s (OAST.Symbol name) =
        let val au = Symbol.au
        in
            if name = au "nil" then
                UnitConstant
            else if name = au "true" then
                BoolConstant true
            else if name = au "false" then
                BoolConstant false
            else
                Variable (lookup s name)
        end
      | alphaRename s (OAST.Let (var, value, body)) =
        let val fresh = freshVar var
          in
              let val s' = (var, fresh) :: s
              in
                  let val body' = alphaRename s' body
                  in
                      Let (fresh, alphaRename s value, body')
                  end
              end
        end
      | alphaRename (OAST.Bind (vars, tup, body)) =
        raise Fail "bind not implemented"
      | alphaRename s (OAST.The (ty, exp)) =
        The (ty, alphaRename s exp)
      | alphaRename s (OAST.Construct (ty, label, exp)) =
        Construct (ty, label, Option.map (alphaRename s) exp)
      | alphaRename s (OAST.ForeignFuncall (name, rt, args)) =
        ForeignFuncall (name, rt, map (alphaRename s) args)
      | alphaRename s (OAST.ForeignNull ty) =
        ForeignNull ty
      | alphaRename s (OAST.SizeOf ty) =
        SizeOf ty
      | alphaRename s (OAST.Operation (f, args)) =
        Operation (f, map (alphaRename s) args)

    (* Public interface *)

    fun transform oast stack =
        alphaRename stack oast

    (* Transform the OAST top-level AST to this top-level AST *)

    fun transformTop ast =
        let
        in
            resetCount ();
            transformTop' ast
        end

    and transformTop' (OAST.Defun (name, params, rt, docstring, ast)) =
        let val params' = mapParams params
        in
            Defun (name,
                   params',
                   rt,
                   docstring,
                   transform ast (paramsToStack params'))
        end
      | transformTop' (OAST.Defgeneric (name, typarams, params, rt, docstring, ast)) =
        let val params' = mapParams params
        in
            Defgeneric (name,
                        typarams,
                        params',
                        rt,
                        docstring,
                        transform ast (paramsToStack params'))
        end
      | transformTop' (OAST.Defclass (name, param, docstring, methods)) =
        Defclass (name,
                  param,
                  docstring,
                  map (fn (OAST.MethodDecl (name, params, rt, docstring)) =>
                          MethodDecl (name, mapParams params, rt, docstring))
                      methods)
      | transformTop' (OAST.Definstance (name, OAST.InstanceArg arg, docstring, methods)) =
        Definstance (name,
                     InstanceArg arg,
                     docstring,
                     map (fn (OAST.MethodDef (name, params, rt, docstring, body)) =>
                             let val params' = mapParams params
                             in
                                 MethodDef (name,
                                            params',
                                            rt,
                                            docstring,
                                            transform body (paramsToStack params'))
                             end)
                         methods)
      | transformTop' (OAST.Deftype tydef) =
        Deftype tydef
      | transformTop' (OAST.Defdisjunction (name, typarams, docstring, variants)) =
        Defdisjunction (name,
                        typarams,
                        docstring,
                        map (fn (OAST.Variant v) => Variant v) variants)
      | transformTop' (OAST.Deftemplate template) =
        Deftemplate template
      | transformTop' (OAST.DefineSymbolMacro mac) =
        DefineSymbolMacro mac
      | transformTop' (OAST.Defmodule module) =
        Defmodule module
      | transformTop' (OAST.InModule name) =
        InModule name

    and mapParams (params: OAST.param list): param list =
        map (fn (OAST.Param (name, ty)) => Param (freshVar name, ty))
            params

    and paramsToStack (list: param list): stack =
        makeStack list
    and makeStack ((Param (n, _))::tail) =
        (Symbol.varSymbol n, n) :: (makeStack tail)
      | makeStack nil =
        nil
end
