# awk-supplement-extractor
Parses awkcode.txt supplement file which contains examples for the book "The Awk Programming Language"

# Description
Extract files from awkcode.txt (provided here: https://www.cs.princeton.edu/~bwk/btl.mirror/awkcode.txt), which is a supplementary material provided by one of the authors of "The Awk Programming Language". This script is helpful because it gives you a TUI menu for selecting an example among the 236 examples provided in that one awkcode.txt resource.

# Usage
The script takes no arguments, simply navigate the menu, when you pick a file and confirm with 'y' it will write that file to your current working directory. The script assumes you have downloaded awkcode.txt and that it exists in the same directory as the script itself.

# Dependencies
If you're on a linux system you should be able to run this program right out-of-the-box. In the script I assume you have bash v4.0+, GNU coreutils, and tput.
