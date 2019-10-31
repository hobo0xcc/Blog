+++
title = "Writing a simple compiler for x86_64"
[taxonomies]
tags = ["compiler"]
+++

Hello!

In this post, i'm going to show how to write a simple compiler from scratch. That means we explore the phases of the compiler e.g. lexer, parser, code generator and so on. If you don't know these phases now, don't worry, we're going to learning these while writing a simple compiler with incremental approach. incremental approach is that writing it with implementing minimal feature as step by step.
Let's go!

# Writing a compiler that returns any number.

In this post, we write a compiler in C. if you don't know C, you need to write it in other language. 
so i won't use some feature that only used in c and other language like c. e.g. C-style macro, gcc extensions.

Let's write first compiler! following code prints assembly which returns number given as argument.

```c
/* main.c */

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
// If argument length is less than 2(in short that means there's no argument).
  if (argc < 2) return 1;
  // Get first argument.
  char *arg = argv[1];
  // Setting assembly syntax to intel one.
  puts(".intel_syntax noprefix");
  // Globalize main function.
  puts(".global _main");
  // main function definition.
  puts("_main: ");
  // Convert string to number and return it.
  // eax is the register that specifying return value in this situation.
  printf("\tmov eax, %d\n", atoi(arg));
  puts("\tret");
  return 0;
}
```

More informations will be explained later, so anyway let's compile this code!
