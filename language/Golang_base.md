# Golang基础

## 1、编写规范

1、go使用静态编译，这意味着其编译后的文件不依赖动态链接库

2、go不能在程序中出现未使用的包和变量，这主要是由于go的编译过程只有报错没有警告。注意，全局变量不受约束，可以声明但不使用。

3、go不需要在语句末尾添加分号。其原理是编译器将句末换行符转化为分号。因此，当一行语句过长需要分为好几行时，换行的位置不能随意选定。比如表达式x+y，只能在+后换行，不能在x后换行，否则会编译错误。这条原则也是函数左括号必须和函数定义在同一行的原因。

4、go默认编码UTF-8，但不推荐用中文

## 2、程序初级结构

### 1、命名

以字母或下划线开头，开头字母大写相当于public，小写为private（必须是包级对象）。习惯上使用驼峰式。

### 2、变量声明与赋值

普通变量的声明方式

参考https://zhuanlan.zhihu.com/p/406830729

```go
// 普通变量声明
var num int = 10	// 标准声明
var num = 10	// 省略类型，直接赋值，由编译器推测类型
var num	int		// 只声明不赋值，go中声明不赋值的变量默认为0/""/false/nil（go语言的null）
num := 10	// 简短变量声明，但不能用于已有变量再赋值，只能声明+赋值，不能用于变量组。

// 连续声明
var num1, num2 int		// 只声明
var num1, num2 int = 10, 20		// 标准声明
var num1, flt2, str3 = 10, 20.0, "30" 	// 多个变量声明赋值且省略类型，类型可以混合。
num1, flt2, str3 := 10, 20.0, "30"		// 声明加赋值的简写
num1, num2 := 10, 30	// 连续使用:=时，需要有至少一个变量没有被声明过
				// 在这种情况下，对于已声明过的变量来说:=退化为赋值运算符，称为“退化赋值”
				// 此种声明赋值方式将无视全局变量，无论如何都会声明一个局部变量

var(	// 变量组的方式声明
    num1 int
    num2 int = 10
    num3 = 10
    num4, num5 = 10, 20		// 也可以一行多个
)

// 赋值方式
num1 = 1		// origin
num1, num2 = 1, 2	// 元组赋值
i, j = j, i		// 元组赋值先计算等号右边的表达式再统一给左边赋值，因此可以达成交换的效果
num1++;num2*=2		// go的自增减是语句不是表达式，和c不同不会有输出，因此没有++i这种写法，也不会有a=b++，只能单成一句。
f, err = os.Open("foo.txt")		// 使用多个变量来承接函数的多个返回值
f, _ = os.Open("foo.txt")		// 用_匿名变量来丢弃不需要的结果
```

与c一样，**变量名只是内存地址的别名**，变量名不占空间，程序在编译运行时都会直接将变量名转化为地址。而Java等语言不同，一切皆指针，变量引用是要占用空间的。

程序初始化的时候，包级变量会在main函数初始化之前就初始化，而局部变量则是运行到声明的那一行才会初始化。

### 3、常量

依然师承c

```Go
const pi = 3.14159		// 常规定义
const (		// 类似变量，常量组的定义方式
    e  = 2.718281
    pi = 3.141592
)

const (		// 定义常量组时不赋值代表和上一个常量一样
    a = 1
    b
    c = 2
    d
)
fmt.Println(a, b, c, d) // "1 1 2 2"

const (		// go中的const代替了c的enum（枚举），使用iota来实现自增
    a = iota	// 0
    b		// 1
    c		// 2
	
    // iota被中断时，必须显示恢复，否则会恢复成复制值的模式
    a = iota	// 0
    b		// 1
    c = 8	
    d		// 8
    
    // iota的多重赋值，同一行值相等
    a, b = iota, iota	// 0, 0
    c, d = iota, iota	// 1, 1
	
    // iota默认int，但也可以转化为其他数字类型
    a float32 = iota	// 0.0
    b		// 1.0
    c		// 2.0
    
    // 要注意的是，iota在常量组一开始就初始化为0且开始自增了，并不是第一次用才置0
    a = 111  // 第一个声明的常量所在的行，此处虽然没有iota，但iota的值被置为0
    b        // b的表达式同上，所以为111，此处虽然没有iota，但因为是新增一个常量声明，所以iota的值加1
    c        // c的表达式同上，所以为111，此处虽然没有iota，但因为是新增一个常量声明，所以iota的值加1
    d = iota // 此处的iota基于前面的基础加1，所以d为3
    
    // 如果使用iota组合计算表达式，后续赋值也会运用表达式
    a = iota
    b = iota * 2 // 2
    c		// 2*2=4
    d        // 3*2=6
)
```

**与c一样，常量依然是“无类型”的。**

首先，什么是常量？参考https://www.zhihu.com/column/c_1375397074024857600

```
111 
3.1 
3.2+12i 
true 
"egon" 

// ”字面“与”硬编码“都是在提醒你，它只是它字面的样子，不要自己意淫它的类型，例如111这个字面量就是一系列阿拉伯数字，你可能会说它难道不是int类型吗，当然不是喽，int类型是编程语言中才有的概念，而阿拉伯数字等人类自然语言的符号早在编程语言诞生之前就已经有了，即便没有编程语言111、3.1，“hello”这些值也都是存在的，比如，你随便找个人让他看看一眼111他都认识，但你跟他讲int类型，除非他是程序员他才能听懂你在讲什么。也就是说，是编程语言将字面量111与数据类型int这两种概念联系到了一起。 综上所述，字面量与数据类型是两件事情
```

为了区分，将此种数据称为字面量。字面量无类型，指的是只有五种字面量，整型只会有整数一种，浮点数也只会有一种浮点数，而不是float32、float64，在理解的时候，最好以自然语言的数字概念去理解。

```
111这种字面量可以被称之为无类型的整数 
3.1这种字面量被称之为无类型的浮点数 
3.2+12i这种字面量被称之为无类型的复数 
true这种字面量被称之为无类型的布尔型 
”egon“这种字面量被称之为无类型的字符
```

字面量和常量的价值在于由于无类型，运算的精度非常高。字面量和常量之间的运算结果也是字面量和常量，只有在将运算结果赋给变量的时候会进行隐式转换，可能丢失精度。常量可以说是保存字面量的一种方式，由于常量也是无类型的，所以不会损失精度。

```
const a = 111 // 无类型整数常量
const b = 3.1 // 无类型浮点数常量
const c = 3.2+12i // 无类型复数常量
const d = true // 无类型布尔常量
const e = "egon" // 无类型字符常量
```

常量的运算、表达式都是在编译期就算出来的。

### 4、指针

和c的用法基本一样

```go
var x int = 10
var p *int:= &x		// 取地址
fmt.Println(*p)		// 取指针所指向的值
*p = 20		// 修改指针所指的值
*p++		// 和c不一样，go通常情况下不会涉及指针运算，因此这里是值+1
p := new(int)	// 创建一个指向匿名int变量的指针，指针在创建的时候无论如何也不会创建空指针

var p = f()
func f() *int {
    v := 1
    return &v
}
fmt.Println(*p)		// 1 是可以如此访问内部变量的，然而这会造成“变量逃逸”，拖慢程序的执行

// 事实上要实现c中的指针运算，可以使用unsafe包下的指令，但不常用
```

### 5、基础类型整合

整型：int int8 int16 int会自动适配操作系统所以尽量用int

浮点数：float32 float64

复数：

```Go
var x complex128 = 1 + 2i
var y complex128 = complex(3, 4) // 3+4i
fmt.Println(real(x))           // 输出实部 "1"
fmt.Println(imag(x))           // 输出虚部 "2"
```

字符：byte，保存字节，本质uint8，使用ASCII编码，rune，保存字符，本质int32，使用utf-8编码

布尔：不能隐式转化为0和1！if 1是无法通过编译的，if bool(1)也不行，没有这种转换方式。

### 6、格式化输出对照

```go
占位符     说明                           举例                   输出
%v        相应值的默认格式。             Printf("%v", people)   {egon}，
%+v       打印结构体时，会添加字段名      Printf("%+v", people)  {Name:egon}
%#v       相应值的Go语法表示            Printf("#v", people)   main.Human{Name:"egon"}
%T        相应值的类型的Go语法表示       Printf("%T", i)            int
%%        字面上的百分号，并非值的占位符   Printf("%%")                %
%t          true 或 false       		  Printf("%t", true)      		  true
%d      十进制表示                             Printf("%d", 0x12)          18
%b      二进制表示                             Printf("%b", 5)             101
%o      八进制表示                             Printf("%d", 10)            12
%x      十六进制表示，字母形式为小写 a-f         Printf("%x", 13)             d
%X      十六进制表示，字母形式为大写 A-F         Printf("%x", 13)             D
%c      相应Unicode码点所表示的字符              Printf("%c", 0x4E2D)        中
%q      单引号括起来的字符字面值，由Go语法安全地转义 Printf("%q", 0x4E2D)       '中'
%U      Unicode格式：U+1234，等同于 "U+%04X"     Printf("%U", 0x4E2D)       U+4E2D
占位符     说明                              举例            输出
%b      无小数部分，二进制指数的科学计数法,Printf("%b\n",a)
        与 strconv.FormatFloat 的 'b' 转换格式一致。例如 -123456p-78
%e      科学计数法，例如 -1234.456e+78        Printf("%e", 10.2)     1.020000e+01
%E      科学计数法，例如 -1234.456E+78        Printf("%e", 10.2)     1.020000E+01
%f      有小数点而无指数，例如 123.456        Printf("%f", 10.2)     10.200000
                                          Printf("%.1f", 10.35)   10.4
%s      输出字符串表示（string类型或[]byte)   Printf("%s", []byte("Go语言"))  Go语言
%q      双引号围绕的字符串，由Go语法安全地转义  Printf("%q", "Go语言")         "Go语言"
%x      十六进制，小写字母，每字节两个字符      Printf("%x", "golang")         676f6c616e67
%X      十六进制，大写字母，每字节两个字符      Printf("%X", "golang")       676F6C616E67
%p            十六进制表示，前缀 0x       fmt.Printf("%p\n", &name)       0xc000010200
```

## 3、流程控制和函数方法

只收录和其他语言相比区别较大的用法

### 1、for

```go
// 1、循环数组
names:=[4]string{"egon","张三","李四","王五"}
for i,v:=range names{
 fmt.Println(i,v)
}
```

### 2、switch

```go
day := 1 
switch day { 
    case 1:    
    fmt.Println("星期一")
    case 6,0:
    fmt.Println("休息日")
    fallthrough // 下一个case分支无论条件是否成立都会执行
    case level >= 10:
    fmt.Println("钻石玩家")
    default:
    fmt.Println("无效的输入！")
}
```

### 3、函数

```Go
func 函数名(参数)(返回值){
    函数体
}
func add(x int,y ...int) int { 	// 可变参数，必须放在最后
    fmt.Println(x,y)
    sum := 0
    for _, v := range y {
        sum += v
    }
    return sum
}
func divmod(x, y int) (int, int) {		// 多个返回值
    res1 := x / y
    res2 := x % y
    return res1, res2
}
```

```go
// 高阶用法
// go支持函数式编程，函数可以当值处理
func square(n int) int { return n * n }
f := square
fmt.Println(f(3)) // "9"

// 函数自然也可以当做返回值
func add(x, y int) int {
    return x + y
}
func sub(x, y int) int {
    return x - y
}
func do(s string) (func(int, int) int, error) {
    switch s {
    case "+":
        return add, nil
    case "-":
        return sub, nil
    default:
        err := errors.New("无法识别的运算符")
        return nil, err
    }
}
func main() {
    f,err:=do("-")
    fmt.Println(f,err)
    fmt.Println(f(111,222))
}

// 既然是函数式编程，当然是要涉及匿名函数和闭包
func counter(start int) func(int) int{
    f:= func(n int) int{	// 定义一个匿名函数
        start += n  // 修改外层函数的变量start
        return start
    }
    return f
}
```

### 4、defer和闭包与匿名函数

```go
func main() {	// 使用defer会在函数结束时逆序执行
    fmt.Println("start...")
    defer fmt.Println(1)
    defer fmt.Println(2)
    defer fmt.Println(3)
    fmt.Println("end...")
}
// start...
// end...
// 3
// 2
// 1

// 下例输出10，defer执行时类似压栈，保存的是压入时候的值
x := 10
defer func(a int) {
		fmt.Println(a)
}(x)
x++

//defer的执行实际及其对返回值的影响是go的经典面试题，较复杂。只能通过用例理解
// Go语言中函数的return不是原子操作，在底层是分为两步来执行
// 第一步：返回值赋值
// defer
// 第二步：真正的RET返回
// 函数中如果存在defer，那么defer执行的时机是在第一步和第二步之间
func f1() int {
    x:=5
    defer  func(){
        x++ // 修改的是x不是返回值
    }()
    return x // 没有返回值变量的情况下，相当于声明了一个临时变量i，x=:5，i=x,x++，return i
}
func f2()(x int){
   defer func(){
        x++
   }()
   return 5 // 有返回值变量，则操作返回值变量。x=5，x++，return x
}
func f3() (y int){
    x:=5
    defer func(){
        x++ // 修改的是x
    }()
    return x  // y = x = 5，x++，return y
}
func f4()(x int){
   defer func (x int){
       x++ // 改变的是函数中x的副本
   }(x)
    return 5 // 虽然返回值变量是x，但是内部函数参数也是x，根据作用域，操作的是内部的x
}
func f5()(x int){
   defer func (x int) int {
       x++
       return x 
   }(x)
    return 5 // 执行了一个完整的函数，x=5，f(5)，return x，传参传的变量值当然不变
}
func f6()(x int){
   defer func (x *int) *int {
       (*x)++
       return x
   }(&x)
   return 5 // 和上例相比传了指针，当然变了
}
func main(){
   fmt.Println(f1()) // 5
   fmt.Println(f2()) // 6
   fmt.Println(f3()) // 5
   fmt.Println(f4()) // 5
   fmt.Println(f5()) // 5
   fmt.Println(f6()) // 6
}

// defer的广泛用法是用来释放锁、关闭资源
func ReadFile(filename string) ([]byte, error) {
    f, err := os.Open(filename)
    if err != nil {
        return nil, err
    }
    defer f.Close()
    return ReadAll(f)
}
```

### 5、异常处理

go使用defer、panic、recover来处理异常

```Go
func funcB() {
    defer func() {
        err := recover()	//如果程序出出现了panic错误,可以通过recover恢复过来，recover必须在defer中
        if err != nil {
            fmt.Println("recover in B")
        }
    }()
    panic("panic in B")		// 使用panic来引发异常
}

// recover后，会返回panic引发的位置。看下面的例子来理清逻辑
func G() {
    defer func() {
        fmt.Println("c")
    }()
    F()
    fmt.Println("继续执行")
}
func F() {
    defer func() {
        if err := recover(); err != nil {
            fmt.Println("捕获异常:", err)
        }
        fmt.Println("b")
    }()
    panic("a")
}
// 捕获异常: a
// b
// 继续执行
// c
```
