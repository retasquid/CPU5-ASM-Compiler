# CPU5-ASM-Compiler
Simple custom ASM compiler for my CPU5.

# How to use
First, write your assembly language in the main.asm file.
Then, run the python script, you can give the asm file name and the output file name in argument like "python compiler.py myfile.asm myoutput.hex", output file can be hex, bin, C header or verilog by default.

You can install the color pack for VScode by pasting the "custom-asm-language" file in C:\Users\{YOUR-NAME}\.vscode\extensions on Windows and in "~/.vscode/extensions/" on Linux/MacOS.
Then modify your extensions.json by adding : 

{"identifier":{"id":"undefined_publisher.custom-asm-language"},"version":"0.0.1","location":{"$mid":1,"path":"/c:/Users/{YOUR-NAME}/.vscode/extensions/custom-asm-language","scheme":"file"},"relativeLocation":"custom-asm-language"}
