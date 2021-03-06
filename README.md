# GOKZ - Discord Module

An optional module for GOKZ that posts server records to a Discord channel using webhooks. 

[**Examples**](https://i.imgur.com/nkp5CdG.png). You can join [my Discord server](https://discord.gg/d79CR3M) to see them for yourself.

Changelogs can be found [here](https://bitbucket.org/zer0k_z/gokz-discord/wiki/).

## Installing ##
 * Make sure your server is up to date.
 * Install GOKZ and all the dependencies if you didn't do it yet.
 * Download and extract gokz-discord-latest.zip from the ``Download`` tab to ``csgo``
 (if you are using gokz-hybrid fork of mine, download ``gokz-discord-hybrid.zip`` instead)
 * Get your webhook URL from your Discord server and replace ``WEBHOOK_URL`` with yours in ``csgo/addons/sourcemod/configs/gokz-discord.cfg``.

### How do I create a Webhook URL? ###

As a server administrator, go on ``Server Settings``  then ``Integrations`` then ``Webhooks``. Click on ``New Webhook``, choose the name of your webhook and its channel, then click on ``Copy Webhook URL`` to obtain the link. 

Changing the webhook's name or channel will **not** alter the link.

### Dependencies ###
 * [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz)  with core, localdb and localranks modules
 * [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)
 * [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)
 
If your GOKZ server is global, it already has all the required dependencies. Note that your server does **not** need to be global in order to use this plugin.

### Missing features ###
 * Support for multiple webhooks
 * Custom run conditions (PRO/NUB records only, top 5/10/20,...)
 * Support for a custom thumbnail server
 * Easy way to disable the plugin

If any feature is highly requested, I will try to work on it.

### Problems? ###

If you have any question, mention me on Discord @zer0.k#2613. Or send me a message through Steam, that works too.

---
Special thanks to zealain for answering all of my dumb questions, Ruto for fixing all of my dumb errors and Zach47 for the thumbnail server.