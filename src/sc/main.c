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
