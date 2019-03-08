#~~
# the rod programming language
# copyright (C) iLiquid, 2018
# licensed under the MIT license
#~~

import sets
import tables

import variant

type
  RodFnSignature* = tuple
    name: string
    arity: int
  RodBaseFn* {.inheritable.} = ref object

    sig*: RodFnSignature

  RodClass* = ref object
    name*: string
    methods*: TableRef[RodFnSignature, RodBaseFn]
    fields*: HashSet[string]
  RodObj* = ref object
    class*: RodClass
    fields*: TableRef[string, RodValue]
    userdata*: Variant

  RodValueKind* = enum
    rvkNull
    rvkBool
    rvkNum
    rvkStr
    rvkObj
    rvkFn
  RodValue* = object
    case kind*: RodValueKind
    of rvkNull: discard
    of rvkBool: boolVal*: bool
    of rvkNum:  numVal*: float
    of rvkStr:  strVal*: string
    of rvkObj:  objVal*: RodObj
    of rvkFn:   fnVal*: RodBaseFn

#~~
# Values and their attributes
#~~

proc `==`*(a, b: RodValue): bool =
  if a.kind == b.kind:
    case a.kind
    of rvkNull: return true
    of rvkBool: return a.boolVal == b.boolVal
    of rvkNum:  return a.numVal == b.numVal
    of rvkStr:  return a.strVal == b.strVal
    of rvkObj:  return a.objVal == b.objVal
    of rvkFn:   return a.fnVal == b.fnVal

proc `$`*(val: RodValue): string =
  result =
    case val.kind
    of rvkNull: "null"
    of rvkBool: $val.boolVal
    of rvkNum: $val.numVal
    of rvkStr: val.strVal
    of rvkObj: "<object " & val.objVal.class.name
    of rvkFn: "<fn " & val.fnVal.sig.name & "(" & $val.fnVal.sig.arity & ")>"

proc `$+`*(val: RodValue): string =
  case val.kind
  of rvkStr: result.addQuoted(val.strVal)
  else: result = $val

proc className*(val: RodValue): string =
  result =
    case val.kind
    of rvkNull: "Null"
    of rvkBool: "Bool"
    of rvkNum:  "Num"
    of rvkStr:  "Str"
    of rvkFn:   "Fn"
    of rvkObj:  val.objVal.class.name

let RodNull* = RodValue(kind: rvkNull)

#~~
# Convenience converters
#~~

converter asBool*(val: RodValue): bool =
  case val.kind
  of rvkNull: return false
  of rvkBool: return val.boolVal
  else: raise newException(ValueError, "The value " & $val & "is not " &
    "implicitly convertible to a boolean")

converter asRodVal*(val: bool): RodValue =
  RodValue(kind: rvkBool, boolVal: val)

converter asRodVal*(val: float): RodValue =
  RodValue(kind: rvkNum, numVal: val)

converter asRodVal*(val: string): RodValue =
  RodValue(kind: rvkStr, strVal: val)

converter asRodVal*(val: RodObj): RodValue =
  RodValue(kind: rvkObj, objVal: val)

converter asRodVal*(val: RodBaseFn): RodValue =
  RodValue(kind: rvkFn, fnVal: val)

#~~
# Classes and objects
#~~

proc newClass*(name: string): RodClass =
  result = RodClass(
    name: name,
    methods: newTable[RodFnSignature, RodBaseFn](),
    fields: initSet[string]()
  )

proc newObject*(class: RodClass, userdata: Variant): RodObj =
  result = RodObj(
    class: class,
    fields: newTable[string, RodValue](),
    userdata: userdata
  )

proc newObject*(class: RodClass): RodObj =
  result = newObject(class, newVariant(nil))

proc `[]`*(obj: RodObj, field: string): RodValue =
  result = obj.fields[field]

proc `[]=`*(obj: var RodObj, field: string, val: RodValue) =
  obj.fields[field] = val
