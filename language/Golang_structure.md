# Golang 复杂类型

## 4、复杂数据结构

### 1、字符串

https://zhuanlan.zhihu.com/p/385624201

```go
var msg string = "hello, world"
// go的字符串的底层是[]byte，即字节数组
s1 := "\110\151" // 底层数组存放的第一个字节是\110，第二个字节是\151
fmt.Println(s1) // Hi
msg[0] = 'L' // go的字符串是不可变的，因此无法编辑：编译错误: cannot assign to msg[0]

// 字符串中的特殊符号当然需要转义
fmt.Println("file_path := \"d:\\a\\b\\c.txt\"") // 输出：file_path := "d:\a\b\c.txt"
// 使用反引号`的字符串表示原生字符串，此时字符串会按照字面处理，不会有任何的转义
fmt.Println(`file_path := "d:\a\b\c.txt"`)

// 索引
s := "hi你好呀"
fmt.Println(s[0]) // 104，UTF-8编码字符是变长的，取不了字符只能取字节
fmt.Println(string(s[0])) // h，可以使用类型转换来输出单字符
// 使用切片也可以转化为字符串输出
fmt.Println(s1[0:1]) // h 前闭后开
fmt.Println(s1[0:2]) // hi
fmt.Println(s1[0:3]) // hi� 一个汉字3个字节，所以取不完会解码失败
fmt.Println(s1[:4]) // hi� 省略第一个参数代表从0开始，省略第二个参数代表到最后结束
fmt.Println(s1[0:5]) // hi你
// 字符串切片和原字符串共享内存，效率很高，放心使用

// 求字符串长度，注意是字节长度不是字符长度
s := "hi你好呀"
fmt.Println(len(s)) // 11 个字节
// 如何求字符串的字符长度？
n := 0
for range s { // range循环会隐式解码字符串，使其遍历字符而不是字节
    n++
}
fmt.Println(n) // 5
// 或者
fmt.Println(utf8.RuneCountInString(s)) // 5

// 实现真正的字符处理？使用[]rune
s := "hi你好呀"
s2 := []rune(s)		// 转化为rune数组，这样就可以像python一样处理字符，也可以修改。
fmt.Println(len(s2)) // 5
fmt.Println(string(s2[2])) // 你
s2[4] = '啊'
fmt.Println(string(s2)) // hi你好啊 修改rune数组是修改的字符

// 常用字符串方法
s := "abc" + "efg" 	// 最常用的字符串拼接方式
b := strings.Join([]string{"abc", "efg"}, "") // join方法传入两个参数，一个字符串数组和一个字符串，用第二个参数作为间隔将第一个参数数组中的字符串元素拼接为一个字符串，可以用来拼接字符串，一般效率比+号高
strings.Replace(str string,old string,new string,n int): // 字符串替换
string.Split(str string,split string): // 返回str split分割的所有子串的slice，类似join
strings.Contains(str string, hasStr string) // 判断是否包含
strings.Index(s string,str string) int: // 判断str在s中首次出现的位置，如果无则返回-1
strings.LastIndex(s string,str string) int: // 判断str在s中最后出现的位置，如果无则返回-1
strings.HasPrefix(s string,prefix string) bool: // 判断字符串s是否以prefix开头
stirngs.HasSuffix(s string,suffix string) bool: // 判断字符串s是否以suffix结尾
```

### 2、数组与切片

数组：一句话，不好用，不常用，不推荐用。

```go
var a [3]int 	// 初始化
var p [3]int = [3]int{1, 2, 3}		// 数组初始化以后默认全0值，可以给定数值初始化
var r [3]int = [3]int{1, 2}		// 不全初始化也是可以的，剩余值默认仍是0
fmt.Println(r[2]) // "0"
q := [...]int{1, 2, 3}		// 不指定长度，让编译器推测
// 不同长度的数组是不同的类型 [3]int != [4]int，不可互相赋值
q = [4]int{1, 2, 3, 4} // compile error: cannot assign [4]int to [3]int
nums := [...]int{1: 1, 5: 2} // 索引初始化数组，如果省略了长度则最大的索引+1就是长度
a := [3][2]string{		// 二维数组的定义
    {"林大牛", "林二牛"},
    {"李一蛋", "李二蛋"},
    {"王一炮", "王三炮"},
}
fmt.Println(a) // [[林大牛 林二牛] [李一蛋 李二蛋] [王一炮 王三炮]]
// 多维数组只有行数可以推测，列数不能省略
a := [...][2]string // 可以
b := [3][...]string // 不行

// 数组是值类型，赋值和传参会复制数组而不是传引用，要在函数里改变数组的值要使用指针
func modifyArray(x [3]int) { // 此函数什么作用都没有
    x[0] = 100
}
```

切片：动态数组





