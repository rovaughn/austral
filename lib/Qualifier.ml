open Identifier
open Imports
open Cst
open Ast

let qualify_identifier (m: import_map) (i: identifier): qident =
  match get_symbol m i with
  | (Some q) -> q
  | None -> make_qident (importing_module m, i, i)

let rec qualify_typespec (m: import_map) (ts: typespec): qtypespec =
  match ts with
  | TypeSpecifier (n, args) ->
     QTypeSpecifier (qualify_identifier m n,
                     List.map (qualify_typespec m) args)
  | ConcreteReadRef (t, r) ->
     QReadRef (qualify_typespec m t, qualify_typespec m r)
  | ConcreteWriteRef (t, r) ->
     QWriteRef (qualify_typespec m t, qualify_typespec m r)
