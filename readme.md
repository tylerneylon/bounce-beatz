# bounce-beatz

This is a table-tennis-inspired (and pong-inspired) game built in Lua
using the Löve game engine.

Why does this exist? Because it's fun to make :)

If you have Löve installed, you can play by typing:

    $ love bounce-beatz.love

from the bounce-beatz directory.

The current code has been tested against Löve 11.4.

![](https://raw.githubusercontent.com/tylerneylon/bounce-beatz/master/img/game_screen1.png)

This started as essentially the simplest video game I could think of.

At it's current stage, instead of level 0 simplicity, I think of this as a level
1/10 (in terms of difficulty to code). I consider the most interesting part of
this code to be the careful coordination between the audio and gameplay. You
can see this in the title screen animation, and especially in the 1-player mode
(not so much in the 2-player mode).

In order to support the audio/gameplay synchronization, I built a small audio
playback library called `beatz`, which acts similarly to a midi player. It can
read in text-based data files that specify when to play certain pitches with
certain instruments (each instrument is specified as binary audio files), as
well as specifying a tempo. The library can play and pause the audio, and
supports callbacks so that your custom lua code can coordinate with the
playback. The `beatz` library is [open source on
github](https://github.com/tylerneylon/beatz).
