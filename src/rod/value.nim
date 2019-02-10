#~~
# rod values
# copyright (C) iLiquid, 2018
#~~

import sequtils
import tables

type
  RodValueKind* = enum
    rvNull ## a null value
    rvBool ## true or false
    rvNum  ## a Nim ``float``
    rvStr  ## a Nim ``string``
    rvObj  ## an object
  RodValue* = object
    ## The base value type in rod. Stores its kind and Nim value, necessary \
    ## for dynamic typing.
    case kind*: RodValueKind
    of rvNull: discard
    of rvBool: boolVal*: bool
    of rvNum:  numVal*: float
    of rvStr:  strVal*: string
    of rvObj:  objVal*: RodObj
  RodClass* = object
    name*: string
  RodObj* = object
    class*: RodClass
  RodVar* = object
    isMutable*: bool
    typeName*: string
    value*: RodValue

proc typeName*(val: RodValue): string =
  case val.kind
  of rvNull: "null"
  of rvBool: "bool"
  of rvNum: "num"
  of rvStr: "str"
  of rvObj: val.objVal.class.name

proc `$`*(value: RodValue): string =
  result.add(value.typeName)
  case value.kind
  of rvBool: result.add(' ' & $value.boolVal)
  of rvNum: result.add(' ' & $value.numVal)
  of rvStr: result.add(' ' & '"' & value.strVal & '"')
  else: discard

proc nullVal*(): RodValue =
  ## Creates a rod null value.
  RodValue(kind: rvNull)

proc boolVal*(val: bool): RodValue =
  ## Creates a rod boolean value.
  RodValue(kind: rvBool, boolVal: val)

proc numVal*(val: float): RodValue =
  ## Creates a rod number value.
  RodValue(kind: rvNum, numVal: val)

proc strVal*(val: string): RodValue =
  ## Creates a rod string value.
  RodValue(kind: rvStr, strVal: val)

proc signature*(mtd: string, args: openArray[string]): string =
  result.add(mtd)
  result.add("(")
  for i, a in args:
    result.add(a)
    if i < len(args) - 1: result.add(",")
  result.add(")")

proc signature*(mtd: string, args: int, argT: string = "_"): string =
  signature(mtd, newSeqWith(args, argT))
