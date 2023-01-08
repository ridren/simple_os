# simple x86 kernel 

## specification

simple kernel for x86 with: 
 * bootloader 
 * interrupts 
 * two VGA video modes (text and 16color)
 * keyboard controler
 * drive controler (reading)
 * simple shell 
 * unused memory manager
 * terminal
 * sound 
 * basic error recovery

these features are VERY basic but they do work
this was project meant for learning basics

kernel itself runs in 32bit protected mode
there is NO memory protection, multitasking and saving to drive

some files contain documentation but not every one, this is intentionall since they are not exactly finished although i do not plan to revisit this project 

## building 
main project:
```
nasm -f bin boot.asm
nasm -f bin kernel.asm
cat 
```
utilities:
```
g++ -O3 utility/<filename>.cpp
```

you also need to add files that are specified in kernel.asm by `%include "<filename>.txt" 
font is already here
or you can comment these lines and everything will work, except for music and images


## Post Mortem

im generally satisfied with how this turned out
although i massively underestimated how much work certain parts do take and i havent even touched any more advanced topics

mistakes:
	macros
		lack standard, complete mess, often broke video specific code because i forgot that macros modify certain registers
	keyboard
		should have been more abstracted
		buffer shouldnt be part of implementation


yup, `not finished, interface still may change` was me handwaving documentation
