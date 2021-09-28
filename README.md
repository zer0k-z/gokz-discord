# GOKZ - Discord Module

![Downloads](https://img.shields.io/github/downloads/zer0k-z/gokz-discord/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/zer0k-z/gokz-discord?style=flat-square) ![Open issues](https://img.shields.io/github/issues/zer0k-z/gokz-discord?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/zer0k-z/gokz-discord?style=flat-square) ![Size](https://img.shields.io/github/repo-size/zer0k-z/gokz-discord?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/zer0k-z/gokz-discord/Compile%20with%20SourceMod?style=flat-square)


An optional module for GOKZ that posts server records to a Discord channel using webhooks. 

[**Examples**](https://i.imgur.com/CbTlTfd.png).

## Installing ##
 * Make sure your server is up to date.
 * Install GOKZ and all the dependencies if you didn't do it yet.
 * Download and extract the latest version of from the ``Release`` tab to ``csgo``
 * Get your webhook URL from your Discord server and replace ``insert webhook here`` with yours in ``csgo/addons/sourcemod/configs/gokz-discord.cfg``.

### Create a Webhook URL ###

As a server administrator, go on ``Server Settings``  then ``Integrations`` then ``Webhooks``. Click on ``New Webhook``, choose the name of your webhook and its channel, then click on ``Copy Webhook URL`` to obtain the link. 

Changing the webhook's name or channel will **not** alter the link.

### Requirements ###
 * Sourcemod and Metamod
 * [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz), with global and/or localranks modules
 * [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556)
 
If your GOKZ server is global, it already has all the required dependencies. Note that your server does **not** need to be global in order to use this plugin.

## Installation ##
1. Make sure your server is up to date.
2. Grab the latest release from the release page and unzip it in your server folder.
**Note**: The plugin has Updater plugin support. If you have Updater installed, do not place the plugins in non-default folder configuration. Doing so might cause duplicate plugins in your server!
3. Restart the server or type `sm plugins load gokz-discord` in the console to load the plugin.
4. The config file will be automatically generated in `cfg/sourcemod/gokz/gokz-discord.cfg`

## Configuration ##
- Webhook configs can be found in `addons/sourcemod/configs/gokz-discord.cfg`.
- You can modify the phrases in `addons/sourcemod/translations/gokz-discord.phrases.txt`.
- Once the plugin has been loaded, you can modify the cvars in `cfg/sourcemod/gokz/gokz-discord.cfg`.

