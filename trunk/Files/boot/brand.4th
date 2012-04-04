\ Copyright (c) 2006-2011 Devin Teske <devinteske@hotmail.com>
\ All rights reserved.
\ 
\ Redistribution and use in source and binary forms, with or without
\ modification, are permitted provided that the following conditions
\ are met:
\ 1. Redistributions of source code must retain the above copyright
\    notice, this list of conditions and the following disclaimer.
\ 2. Redistributions in binary form must reproduce the above copyright
\    notice, this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution.
\ 
\ THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
\ ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
\ IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
\ ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
\ FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
\ DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
\ OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
\ HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
\ LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
\ OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
\ SUCH DAMAGE.
\ 
\ $FreeBSD: src/sys/boot/forth/brand.4th,v 1.1.2.1.2.1 2011/11/11 04:20:22 kensmith Exp $

marker task-brand.4th

variable brandX
variable brandY

\ Initialize logo placement
2 brandX !
1 brandY !

: fbsd-logo ( x y -- ) \ "FreeBSD" [wide] logo in B/W (7 rows x 42 columns)

    2dup at-xy ."  ____   _____ _____   ____  ____  " 1+
    2dup at-xy ." |  _ \ / ____|  __ \ |  _ \|  _ \ " 1+
    2dup at-xy ." | |_) | (___ | |  | || |_) | |_) |" 1+
    2dup at-xy ." |  _ < \___ \| |  | ||    /|  __/ " 1+
    2dup at-xy ." | |_) |____) | |__| || |\ \| |    " 1+
    2dup at-xy ." |     |      |      || | | | |    " 1+
         at-xy ." |____/|_____/|_____/ |_| |_|_| 1.2"

    \ Put the cursor back at the bottom
    0 25 at-xy
;

\ This function draws any number of company logos at (loader_brand_x,
\ loader_brand_y) if defined, or (2,1) (top-left) if not defined. To choose
\ your logo, set the variable `loader_brand' to the respective logo name.
\ 
\ Currently available:
\
\ 	NAME        DESCRIPTION
\ 	fbsd        FreeBSD logo
\ 
\ NOTE: Setting `loader_brand' to an undefined value (such as "none") will
\       prevent any brand from being drawn.
\ 
: draw-brand ( -- )

	s" loader_brand_x" getenv dup -1 <> if
		?number 1 = if
			brandX !
		then
	else
		drop
	then

 	s" loader_brand_y" getenv dup -1 <> if
 		?number 1 = if
			brandY !
		then
 	else
		drop
	then

	s" loader_brand" getenv dup -1 = if
		brandX @ brandY @ fbsd-logo
		drop exit
	then

	2dup s" fbsd" compare-insensitive 0= if
		brandX @ brandY @ fbsd-logo
		2drop exit
	then

	2drop
;
