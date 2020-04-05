import tables
import times
import unittest

import rod/private/scanner
import rod/private/parser
import rod/private/chunk
import rod/private/codegen
import rod/private/disassembler
import rod/private/rodlib

template benchmark(name, body) =
  let t0 = epochTime()
  body
  echo name, " took ", (epochTime() - t0) * 1000, "ms"

template compile(input: string) =
  benchmark("compilation"):
    var scanner = initScanner(input, "testcase.rod")
    let ast = parseScript(scanner)
    var
      main = newChunk()
      script = newScript(main)
      system = script.modSystem()
      module = newModule("testcase")
      cp = initCodeGen(script, module, main)
    module.load(system)
    cp.genScript(ast)
  echo module
  echo `$`(script, {
    "system.rod": RodlibSystemSrc,
    "testcase.rod": input,
  }.toTable)

suite "compiler":
  test "variables":
    compile("""
      var a = 2 + 2
      var b = 2 + a
    """)
  test "blocks":
    compile("""
      { var a = 10
        { var a = a } }
      { var a = 12
        a = a + 3 }
    """)
  test "if expressions":
    compile("""
      let x = true
      if x {
        var x = 2
      } elif false {
        var y = 3
      } elif false {
        var z = 4
      } else {
        var w = 5
      }
    """)
    compile("""
      let x = if true { 2 }
              else { 4 }
    """)
  test "while loops":
    compile("""
      let x = true
      while x {
        let y = 1
      }
    """)
    compile("""
      while true {
        let y = 1
      }
    """)
    compile("""
      while false {
        let y = 1
      }
    """)
    compile("""
      var x = 0
      var stop = false
      while x < 10 and not stop {

      }
    """)
    compile("""
      var x = 0
      while true {
        x = x + 1
        if x == 10 {
          break
        }
      }
    """)
  test "objects":
    compile("""
      object Hello {
        x, y: number
      }

      var instance = Hello(x: 10, y: 20)
      var x = instance.x
      instance.y = 30
    """)
  test "procs":
    compile("""
      echo("Hello!")
    """)
    compile("""
      proc sayHello(target: string) {
        echo("Hello, ")
        echo(target)
        echo("!")
      }
    """)
    compile("""
      proc fac(n: number) -> number {
        result = 1
        var i = 1
        while i <= n {
          result = result * i
          i = i + 1
        }
      }
    """)
  test "generic objects":
    compile("""
      object Pair[T] {
        a, b: T
      }

      var p = Pair[number](a: 1, b: 2)
    """)
  test "generic procs":
    compile("""
      proc print[T](x, y, z: T) {
        echo($x)
        echo($y)
        echo($z)
      }

      print(1, 2, 3)
    """)
  test "generic iterators":
    compile("""
      object Tri[T] {
        a, b, c: T
      }

      var t = Tri[number](a: 1, b: 2, c: 3)

      iterator vertices[T](tri: Tri[T]) -> T {
        yield tri.a
        yield tri.b
        yield tri.c
      }

      for vert in vertices(t) {
        echo($vert)
      }
    """)
