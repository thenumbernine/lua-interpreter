[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KYWUWS86GSFGL)

A drop-in interpreter for your scripts.
Especially useful if you find that `debug.debug()` function too limited.

Usage:

	require 'interpreter'(_ENV)

This brings you to a familiar `> ` prompt.
I don't support incomplete statements just yet.
I guess that's just a matter of catcing 'expected' errors when loading strings.  
I'll do that later.

I also don't support `_PROMPT` or `_PROMPT2` yet.

I do support upvalue access, so you should be able to read and write locals from your calling functions.
