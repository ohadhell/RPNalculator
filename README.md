# RPNalculator
calculator for unlimited-precision unsigned integers, Reverse Polish notation, written in assembly

Reverse Polish notation (RPN) is a mathematical notation in which every operator follows all its operands, for example "3 + 4" would be presented as "3 4 +"
Actions:
‘q’ – quit
‘+’ – unsigned addition
pop two operands from operand stack, and push the result, their sum
‘p’ – pop-and-print
pop one operand from the operand stack, and print its value to stdout
‘d’ – duplicate
push a copy of the top of the operand stack onto the top of the operand stack
‘&’ - bitwise AND, X&Y with X being the top of operand stack and Y the element next to x in the operand stack.
pop two operands from the operand stack, and push the result.
‘n’ – number of bytes the number is taking (note: same as half the hexadecimal digits rounded up)
pop one operand from the operand stack, and push one result.
‘*’ – unsigned multiplication (optional* - won't be checked)
pop two operands from operand stack, and push the result, their product

Operations are performed as is standard for an RPN calculator: any input number is pushed onto an operand stack. Each operation is performed on operands which are popped from the operand stack. The result, if any, is pushed onto the operand stack. The output can contain leading zeros.
The stack:
a separate operand stack of size 5 by default. In order to change it to a different number, the user enter a command-line argument, the opereand stack size in octal digits. works correctly with any operand stack size greater than 2.
