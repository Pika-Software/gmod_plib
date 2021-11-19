# PLib
Powerful GLua Library

<img align="right" src="https://i.imgur.com/j5DjzQ1.png"></img>
- **What is it?**  
	*This is a **Pika Library** - a auxiliary library for development in Garry's Mod. It can be used as a dependency for other addons or as an improvement that eliminates many problems in the game and the addons development, making everything easier and more stable.*
- **Where is the documentation?**  
	*We're still making, please wait...*
- **Can I use it for my addons?**  
	*Of course, this library is completely open for use by other developers, only if you are going to publish an addon, __do not include the library code in it!__ This will cause compatibility errors with new versions and also threatens errors in the future due to the lack of library code updates. Instead, use the "Necessary items" by specifying this addon.*
- **What functionality does this library have?**  
	*So far, the library is under early development and will be replenished, in the future we plan to develop the library as a package manager in which you and your addons will choose which functionality to download and use.*
- **I want to (report a bug/suggest improvements)!**  
	*You can write your problem/suggestion in __Issues__.*  
  
____
**At the moment we have:**  
  
- **Achievement system, similar to the game**
- **Custom notifications (not replacing the originals)**
- **Standby screen with customizable logo and fading**
- **More (Pre\*, On\*, Post\*) hooks for different purposes**
- **Developer HUD and concommands for convenient debugging**
- **Improved some built-in library functions**
- **GMAD file format builder**
- **Improvements in the environment and rendering**
- **Arithmetic operations with strings**
  
**And a lot of cool new functions can be used from PLib!** 

____
![](https://img.shields.io/github/downloads/Pika-Software/plib/total?style=for-the-badge)
![](https://img.shields.io/github/commit-activity/m/Pika-Software/plib?style=for-the-badge&logo=github)
![](https://img.shields.io/github/license/Pika-Software/plib?style=for-the-badge)
![](https://img.shields.io/steam/favorites/2628028051?label=Steam%20Favorites&style=for-the-badge&logo=steam)
![](https://img.shields.io/steam/subscriptions/2628028051?label=Steam%20Subscriptions&style=for-the-badge&logo=steam)

[![](https://img.shields.io/badge/Workshop%20Page-Steam-%232a475e?style=for-the-badge&logo=steam)](https://steamcommunity.com/sharedfiles/filedetails/?id=2628028051)
[![](https://img.shields.io/badge/Pika%20Software-Discord-%237289da?style=for-the-badge&logo=discord)](https://discord.gg/3UVxhZj)
[![](https://img.shields.io/badge/Pika%20Software-Hub-%231b242c?style=for-the-badge&logo=data:image/png;base64,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)](https://hub.pika-soft.ru)
