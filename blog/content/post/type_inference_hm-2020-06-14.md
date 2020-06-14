---
title: "型推論の実装"
date: 2020-06-14
tags:
categories: ["Compiler"]
tags: ["Type Inference", "Compiler Construction", "C"]
draft: true
math: true
---

この記事では、主に型推論の実装方法について書いていきます。
理論的な側面は必要最低限に留めますので、詳しく知りたい方は参考文献を参照してください。

# 型推論とは何か

型推論とは何かについて軽く説明しておきましょう。

型推論とは、プログラムの変数や引数などの型を、明示的な指定がなくても自動的に推論し、決定する機構のことです。
たとえば、以下のようなOCamlプログラムを考えてみましょう。

```OCaml
let f x y = x + y;;
```

このプログラムは`x`と`y`を引数として、それらの和を返しています。OCamlのREPLで実行してみると、この関数は引数として整数を2つ持ち、整数を返す関数として定義されます。
`x`と`y`には何も型を指定していないのに、整数であると決定されるわけです。

```OCaml
val f : int -> int -> int = <fun>
```

このように、型推論は型を**周辺状況**や**文脈**などから決定してくれます。

上記の例では、`+`演算子が左辺と右辺に整数をとり、整数を返す、という情報から関数の型を推論しています。このような単純な型推論は比較的簡単に実装できるでしょう。

今度は少し複雑な例を考えてみましょう。

```OCaml
let a x y z = if x == 2 then y else z(x - 1)
```

この関数は以下の型を持ちます。

```OCaml
val a : int -> 'a -> (int -> 'a) -> 'a = <fun>
```

整数、任意の型`x`、引数として整数を持ち、任意の型`x`を返す関数、これらを引数として、任意の型`x`を返す関数、という型を持っています。

それぞれの引数について、なぜその型を持つのかについて説明します。

`x`は整数型を持っています。これは、`x == 2`の部分から推論されています。`==`演算子は左辺と右辺に同じ型をとるので、右辺の`2`と同じ型を持っていなくてはなりません。このことから、`x`は整数型を持つことがわかります。

`y`は任意の型`x`を持っています。これは、型推論で型が特に決定されなかったことを意味しています。あとで説明しますが、これは、**型変数**が置き換わらなかった場合です。

`z`は引数として整数型を持ち、任意の型`x`を返します。引数に整数型を持つのは、先ほどの例と同様に、`x - 1`が整数型を持つためです。では、任意の型を返すのは何故でしょうか。これは、If文の制約に関係しています。If文は条件式に真偽型を持ち、thenとelseの部分で同じ型を持つようになっています。そのため、`z`が返す型は`y`と同じ任意の型`x`になります。

型推論を人力で行おうとすると、このような感じになります。

次の章では、型推論がどのようにして実行されるかについて解説します。

# 型推論の大まかな流れ

型推論は、以下のようなステップを踏みます。

1. すでに明らかなものに型をつける。
2. 現時点で明らかでないものに型変数をつける。
3. 型の連立方程式を立てる
4. 単一化(Unification)して、型変数についての代入(Substitution)を生成する。

1つめのステップでは、12や42のような整数値、trueやfalseのような真偽値などにそれぞれの型を付けます。これらはすでに明らかなので、そのまま代入します。

2つめのステップでは、**明らかでない**ものに型変数を代入します。たとえば、関数の引数などは最初のステップでは明らかでないので、型変数が代入されます。

3つめのステップでは、型についての連立方程式を立てます。これは数学の連立方程式と同じように、どの型とどの型が等しい(= 同じ型を持つ)かを方程式にします。たとえば、If文の条件式は真偽型と等しく、thenとelseの型は等しい、といった感じです。

4つめのステップでは、単一化(Unification)という作業を行います。これは、2つの型が与えられた時、型変数を置き換えて(= 型変数を消して)、型を等しくします。

次の章では、型の連立方程式と単一化について詳しく説明します。

# 型の連立方程式と単一化

型の連立方程式は、言語の制約から、どの型とどの型が等しいかを方程式にして並べたものと考えることができます。

先ほどの例を型の連立方程式の観点からもう一度考えてみましょう。

```OCaml
let a x y z = if x == 2 then y else z(x - 1)
```

例えば、`x == 2`の部分はIf文のルールから、真偽型と等しいことがわかります。さらに、`then y else z(x - 1)`の`y`と`z(x - 1)`も等しいことがわかります。

このように、言語の制約(= ルール)から、型の連立方程式を立てていきます。

## 言語の型付け規則

ここで、言語の制約を書くのに便利な記法として、型付け規則について解説します。

型付け規則は以下のような記法になっています。

$$
\frac{\Gamma \vdash e_0 : \tau \rightarrow \tau ' \quad \Gamma \vdash e_1 : \tau}{\Gamma \vdash e_0 e_1 : \tau ' }
$$

一見すると複雑なように思えますが、一つづつ読み解いていきましょう。

まず、 $ {\Gamma \vdash e_0 : \tau \rightarrow \tau ' } $ を考えます。

ここで、 $ \Gamma $ は型環境を表しています。型環境は、式とそれに対応する型の集合です。式 $ e $ が型環境 $ \Gamma $ において型 $ \tau $ を持つことを以下のように表します。

$$ \Gamma \vdash e : \tau $$

さて、先ほどの例に戻ると、 $ \Gamma \vdash e_0 : \tau \rightarrow \tau ' $ は、型環境 $ \Gamma $ において、式 $ e_0 $ は $ \tau $ を引数に取り、 $ \tau ' $ を返す関数、となります。

$ \Gamma \vdash e_1 : \tau $ も同様です。

次に、先ほどの例の下の部分、 $ \Gamma \vdash e_0 e_1 : \tau ' $ を考えます。

ここで、型付け規則を $ \frac{g}{d} $ と表した時、その意味は、 $ g $ が与えられた時、 $ d $ が導かれる、となります。

そのことを踏まえると、 $ \Gamma \vdash e_0 e_1 : \tau ' $ は、 $ \Gamma \vdash e_0 : \tau \rightarrow \tau ' \quad \Gamma \vdash e_1 : \tau $ が与えられた時に導かれる規則となります。

さて、 $ \Gamma \vdash e_0 e_1 : \tau ' $ は、関数 $ e_0 $ に引数 $ e_1 $ を適用した時、この式の型は $ \tau ' $ 、という意味になります。

## 型の連立方程式の生成

If文は以下の型付け規則を持っているとします。

$$
\frac{\Gamma \vdash e_0 : \mathtt{Bool} \quad \Gamma \vdash e_1 : \tau \quad \Gamma \vdash e_2 : \tau}{\Gamma \vdash \mathtt{if} e_0 \mathtt{then} e_1 \mathtt{else} e_2 : \tau}
$$

この時、$ e_0 = \mathtt{Bool} $ と $ e_1 = e_2 = \tau $ という2つの方程式が生成されます。

これがIf文から生成される方程式です。実装ではVectorやListに方程式を追加していきます。

同様に、`+`演算子や`==`演算子の型付け規則も定義できます。

$$
\frac{\Gamma \vdash e_0 : \mathtt{Int} \quad \Gamma \vdash e_1 : \mathtt{Int}}{\Gamma \vdash e_0 + e_1 : \mathtt{Int}}
$$

$$
\frac{\Gamma \vdash e_0 : \tau \quad \Gamma \vdash e_1 : \tau}{\Gamma \vdash e_0 \mathtt{==} e_1 : \mathtt{Bool}}
$$

このような型付け規則から型の連立方程式を生成していきます。

## 単一化

2つの型が与えられた時、それらを等しくする型変数への代入(Substitution)を決定するのが単一化です。

例えば、以下のような2つの関数型を単一化することを考えましょう。
ここで、大文字は型変数、小文字は定数、g(...)のようなものは関数の適用とします。

`f(V, a, K)`

`f(v, U, bar(U))`

これらを等しくするような型変数への代入を考えます。

まず、一番左をみると、{V=v}と代入すれば良いことがわかります。

次に、左から2番目をみると、{V=v, U=a}となります。

一番右をみると、これは{V=v, U=a, K=bar(U)}となります。

関数型についてはこのように単一化できます。

## 単一化のアルゴリズム

単一化のアルゴリズムをPythonに似た疑似コードで示します。

```python
def unify(x, y, subst): # xとyは方程式の左辺と右辺。substは代入。
    if x == y:
        return Success # xとyが等しい時は何もしない。
    elif x is Type Variable:
        return unify_variable(x, y, subst)
    elif y is Type Variable:
        return unify_variable(y, x, subst)
    elif x is Function and y is Function: # xとyが関数型だった場合
        if x.arg_length() != y.arg_length: # xとyの引数の数が違う
            return Failed
        try unify(x.return_type, y.return_type, subst) # 関数の戻り値の型を単一化
        for i in range(len(x.args)):
            try unify(x.args[i], y.args[i], subst) # 引数の単一化
    else:
        return Failed

def unify_variable(v, x, subst):
    if v in subst: # vの代入がすでに存在した時
        return unify(subst[v], x, subst) # vの代入の型とxを単一化
    elif x is Type Variable and x in subst: # xが型変数で、代入がすでに存在していた時
        return unify(v, subst[x], subst)
    elif occurs_check(v, x, subst): # vがxに登場した場合、無限ループに陥る可能性がある
        return Failed
    else:
        subst[v] = x
        return Success

def occurs_check(v, t, subst): # 型変数vが型tに現れるか
    if v == t:
        return True
    elif t is Type Variable and t in subst:
        return occurs_check(v, subst[t], subst)
    elif t is Function:
        for i in range(len(t.args)): # 引数にvが現れるか
            if occurs_check(v, t.args[i], subst):
                return True
    
    return False
```

# 参考文献

- [https://eli.thegreenplace.net/2018/unification/](https://eli.thegreenplace.net/2018/unification/)
- [https://eli.thegreenplace.net/2018/type-inference/](https://eli.thegreenplace.net/2018/type-inference/)
- [https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system)
- [Basic Type checking](http://lucacardelli.name/Papers/BasicTypechecking.pdf)
- [An Efficient Unification Algorithm](http://www.nsl.com/misc/papers/martelli-montanari.pdf)
- [Correcting A Widespread Error in Unification Algorithms](https://norvig.com/unify-bug.pdf)