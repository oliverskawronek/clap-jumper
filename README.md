# Clap Jumper
A 3D game. Jump from platform to platform by clapping your hands and reach the finish. This game demonstrates how to control a game by audio. It was made for the presentation *Spiele mit Musik steuern* hold on [*Lange Nacht der Computerspiele, Leipzig*](http://www.schreibfabrik.de/spielenacht/vortraege.php) in 2015.

# Module Dependencies
Please make sure you have the following modules already installed:
* [**sidesign.mod/minib3d.mod**](https://github.com/si-design/minib3d "3D engine")
* [**vertex.mod/openal.mod**](https://github.com/oliverskawronek/openal.mod "Audio engine")

# How to use
Run **Game.bmx**. You will see a list of capture devices. The default capture device will be used. To change the capture device open **Game.bmx** and replace the line (near line 655)

```BlitzMax```
recorder.Open(devices[index]) ' edit index for your capture device (starting by 0)
```

The game is controlled by audio. When you clap in your hands the player will jump in its current direction. The strength of your clapping matters. You can also press **[Space]** key for jumping if your audio settings doesn't work.

# Screenshot
![Screenshot](https://cloud.githubusercontent.com/assets/10528519/8040006/93d03b04-0e0d-11e5-9f12-7099535c0eb5.png)


