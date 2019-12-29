import times
import unittest

import rod/private/scanner
import rod/private/parser
import rod/private/chunk
import rod/private/codegen
import rod/private/disassembler

template benchmark(name, body) =
  let t0 = epochTime()
  body
  echo name, " took ", (epochTime() - t0) * 1000, "ms"

template dumpTokens(input: string) =
  var
    scanner = initScanner(input, "dump.rod")
    token: Token
  while true:
    token = scanner.next()
    echo token
    if token.kind == tokEnd:
      break

template compile(input: string) =
  dumpTokens(input)
  benchmark("compilation"):
    var scanner = initScanner(input, "testcase.rod")
    let ast = parseScript(scanner)
    var
      main = newChunk()
      script = newScript(main)
      system = script.systemModule()
      module = newModule("testcase")
      cp = initCodeGen(script, module, main)
    module.load(system)
    cp.genScript(ast)
  echo ast
  echo module
  echo main.disassemble(input)

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
