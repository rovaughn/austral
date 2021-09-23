open Identifier
open ModuleSystem
open BuiltIn
open CppPrelude
open ParserInterface
open CombiningPass
open ExtractionPass
open TypingPass
open CodeGen
open CppRenderer
open Cst
open Type
open Error

let append_import_to_interface ci import =
  let (ConcreteModuleInterface (mn, imports, decls)) = ci in
  if equal_module_name mn pervasive_module_name then
    ci
  else
    ConcreteModuleInterface (mn, import :: imports, decls)

let append_import_to_body cb import =
  let (ConcreteModuleBody (mn, kind, imports, decls)) = cb in
  if equal_module_name mn pervasive_module_name then
    cb
  else
    ConcreteModuleBody (mn, kind, import :: imports, decls)

type compiler = Compiler of menv * string

let cmenv (Compiler (m, _)) = m

let compiler_code (Compiler (_, c)) = c

let rec compile_mod c is bs =
  let ci = parse_module_int is
  and cb = parse_module_body bs
  and menv = cmenv c in
  let ci' = append_import_to_interface ci pervasive_imports
  and cb' = append_import_to_body cb pervasive_imports in
  let combined = combine menv ci' cb' in
  let semantic = extract menv combined in
  let menv' = put_module (cmenv c) semantic in
  let typed = augment_module menv' combined in
  let cpp = gen_module typed in
  let code = render_module cpp in
  Compiler (menv', (compiler_code c) ^ "\n" ^ code)

let rec compile_multiple c modules =
  match modules with
  | (is, bs)::rest -> compile_multiple (compile_mod c is bs) rest
  | [] -> c

let rec check_entrypoint_validity menv qi =
  match get_decl menv qi with
  | Some decl ->
     (match decl with
      | SFunctionDeclaration (vis, _, typarams, params, rt) ->
         if vis = VisPublic then
           if typarams = [] then
             match params with
             | [ValueParameter (_, pt)] ->
                if is_root_cap_type pt then
                  if is_root_cap_type rt then
                    ()
                  else
                    err "Entrypoint function must return a value of type Root_Capability."
                else
                  err "Entrypoint function must take a single argument of type Root_Capability."
             | _ ->
                err "Entrypoint function must take a single argument of type Root_Capability."
           else
             err "Entrypoint function cannot be generic."
         else
           err "Entrypoint function is not public."
      | _ ->
         err "Entrypoint is not a function.")
  | None ->
     err "Entrypoint does not exist."

and is_root_cap_type = function
  | NamedType (name, [], LinearUniverse) ->
     let m = equal_module_name (source_module_name name) pervasive_module_name
     and n = equal_identifier (original_name name) root_cap_type_name in
     m && n
  | _ ->
     false

let entrypoint_code mn i =
  let f = (gen_module_name mn) ^ "::" ^ (gen_ident i) in
  "int main() {\n    " ^ f ^ "(false);\n    return 0;\n}\n"

let compile_entrypoint c mn i =
  let qi = make_qident (mn, i, i) in
  check_entrypoint_validity (cmenv c) qi;
  let (Compiler (m, c)) = c in
  Compiler (m, c ^ "\n" ^ (entrypoint_code mn i))

let empty_compiler =
  let menv = put_module empty_menv memory_module in
  let menv = put_module menv pervasive_module in
  let c = Compiler (menv, prelude) in
  c