local util = require("spec.util")

describe("record method call", function()
   it("method call on an expression", util.check([[
      local r = {
         x = 2,
         b = true,
      }
      function r:f(a: number, b: string): boolean
         if self.b then
            return #b == 3
         else
            return a > self.x
         end
      end
      (r):f(3, "abc")
   ]]))

   it("method call with different call forms", util.check([[
      local foo = {bar = function(x: any, t: any) end}
      print(foo:bar())
      print(foo:bar{})
      print(foo:bar"hello")
   ]]))

   it("catches wrong use of : without a call", util.check_syntax_error([[
      local foo = {bar = function(x: any, t: any) end}
      print(foo:bar)
   ]], {
      { y = 2, msg = "expected a function call" },
   }))

   it("nested record method calls", util.check([[
      local r = {
         x = 2,
         b = true,
      }
      function r:f(b: string): string
         if self.b then
            return #b == 3 and "yes" or "no"
         end
         return "what"
      end
      local function foo()
         r:f(r:f("hello"))
      end
   ]]))

   describe("lax", function()
      it("nested record method calls", util.lax_check([[
         local SW = {}

         function SW:write(arg1,arg2,...)
         end

         function SW:writef(fmt,...)
            self:write(fmt:format(...))
         end
      ]], {
         { msg = "arg1" },
         { msg = "arg2" },
         { msg = "fmt" },
         { msg = "fmt.format" },
      }))
   end)

   describe("catches wrong use of self.", function() 
   
      it("in call for top-level method", util.check_type_error([[
         local record Foo
         end
         function Foo:method_a()
         end
         function Foo:method_c(arg: string)
         end
         function Foo:method_b()
            self.method_a()
            self.method_c("hello")
         end
      ]], {
         { y = 8, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 9, msg = "invoked method as a regular function: use ':' instead of '.'" },
      }))

      it("in call for method declared in record", util.check_type_error([[
         local record Foo
            method_a: function(self: Foo)
            method_c: function(self: Foo, other: Foo)
         end
         function Foo:method_b(other: Foo)
            self.method_a()
            self.method_c(other)
         end
      ]], {
         { y = 6, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 7, msg = "invoked method as a regular function: use ':' instead of '.'" },
      }))

      it("in call for method declared in nested record", util.check_type_error([[
         local record Foo
            record Bar
               method_a: function(self: Bar)
               method_c: function(self: Bar, other: Bar)
            end
         end
         local function function_b(bar: Foo.Bar)
            bar.method_a()
            bar.method_c(bar)
         end
      ]], {
         { y = 8, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 9, msg = "invoked method as a regular function: use ':' instead of '.'" },
      }))

      it("in call for method declared in type record", util.check_type_error([[
         local type Foo = record
            method_a: function(self: Foo)
            method_c: function(self: Foo, arg: string)
            type Bar = record
               method_d: function(self: Bar)
               method_e: function(self: Bar, other: Bar)
            end
         end
         function Foo:method_a()
         end
         function Foo:method_c(arg: string)
         end
         function Foo:method_b()
            self.method_a()
            self.method_c("hello")
         end
         local function function_f(bar: Foo.Bar)
            bar.method_d()
            bar.method_e(bar)
         end 
      ]], {
         { y = 14, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 15, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 18, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 19, msg = "invoked method as a regular function: use ':' instead of '.'" },
      }))

      it("in call for method declared in generic record", util.check_type_error([[
         local record Foo<T>
            method_a: function(self: Foo<T>)
            method_c: function(self: Foo<T>, other: Foo<T>)
         end
         local function function_b<T>(first: Foo<T>, second: Foo<T>)
            first.method_a()
            first.method_c(second)
         end
      ]], {
         { y = 6, msg = "invoked method as a regular function: use ':' instead of '.'" },
         { y = 7, msg = "invoked method as a regular function: use ':' instead of '.'" },
      }))
   
   end)

   describe("accepts correct use of self:", function() 
   
      it("in call for top-level method", util.check([[
         local record Foo
         end
         function Foo:method_a()
         end
         function Foo:method_c(arg: string)
         end
         function Foo:method_b()
            self:method_a()
            self:method_c("hello")
         end
      ]]))
   
      it("in call for method declared in record", util.check([[
         local record Foo
            method_a: function(self: Foo)
            method_c: function(self: Foo, other: Foo)
         end
         function Foo:method_b(other: Foo)
            self:method_a()
            self:method_c(other)
         end
      ]]))
   
      it("in call for method declared in nested record", util.check([[
         local record Foo
            record Bar
               method_a: function(self: Bar)
               method_c: function(self: Bar, other: Bar)
            end
         end
         local function function_b(bar: Foo.Bar)
            bar:method_a()
            bar:method_c(bar)
         end
      ]]))

      it("in call for method declared in type record", util.check([[
         local type Foo = record
            method_a: function(self: Foo)
            method_c: function(self: Foo, arg: string)
            type Bar = record
               method_d: function(self: Bar)
               method_e: function(self: Bar, other: Bar)
            end
         end
         function Foo:method_a()
         end
         function Foo:method_c(arg: string)
         end
         function Foo:method_b()
            self:method_a()
            self:method_c("hello")
         end
         local function function_f(bar: Foo.Bar)
            bar:method_d()
            bar:method_e(bar)
         end 
      ]]))
   
      it("in call for method declared in generic record", util.check([[
         local record Foo<T>
            method_a: function(self: Foo<T>)
            method_c: function(self: Foo<T>, other: Foo<T>)
         end
         local function function_b<T>(first: Foo<T>, second: Foo<T>)
            first:method_a()
            first:method_c(second)
         end
      ]]))

   end)

end)
