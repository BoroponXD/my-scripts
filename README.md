Hi! That's my repository where im making my own scripts. Well, here's guide for Jule's RNG script. (Sorry if my english is bad qwq)
Necessary to read ALL if u want to get stats in real time.

What is this guide for?
i've made stat save for this script, so script saving them and u can make the bot for Telegram, to get your stats now. (Updates every 5 minutes)

So, what u need to do for a bot?
Firstly, go to the telegram and find "BotFather" and type: "/newbot".
U need to name your bot, then you'll get the token (don't share to anyone).
When u made a Telegram bot, go to him and type "/start" (it won't work without it).
Also you need to get your Telegram ID (necessary). 
Go to this site: https://api.telegram.org/bot"TOKEN"/getUpdates 
(change "<TOKEN>" to your bot token, it shall look like this: 
https://api.telegram.org/bot1234567890:XXXX/getUpdates)
Well, when you're there, you're gonna get sum like this:

{"ok":true,"result":[{"update_id":XXXXXXXXX,"message":{"message_id":1,"from":{"id":XXXXXXXX,"is_bot":false,"first_name":".","language_code":"ru"},"chat":{"id":XXXXXXXX,

Here u need <"from":{"id":XXXXXXXX> or <"chat":{"id":XXXXXXXX>.

Well, when u get your Telegram ID and your bot token,
u need to go to the folder where your stats saving 
(NOT ALL EXECUTORS SUPPORT "writefile", SO IT CANNOT WORK WITH SOME EXECUTORS)
im using Xeno, so for me it's C:\Users\MYUSER\Desktop\Xeno\workspace, but for you may be other.

Oh! Almost forgot about u need to download node.js : https://nodejs.org/en

Well, when u find your folder, where your stats saving, u need to open CMD here.
Just open cmd and there type <cd C:"your-folder-path">.
When you opened cmd in the folder(and installed node.js), type:

npm init -y
npm install axios

Then go to your folder again and create there sum like "SendStats.js".
Now we need to paste there a script that will send us the stats. (Recommended to edit with Notepad++ : https://notepad-plus-plus.org/ )
Open the file "SendStats.js" to edit it and paste there this script (made by me):
(YOU HAVE TO CHANGE "YOUR ID" AND "YOUR TOKEN" THERE)

https://github.com/BoroponXD/my-scripts/blob/main/telegram-stats-bot

Save the file and launch cmd in the folder again.
Then type "node SendStats.json".
Well done! Now just launch the script (Jule's RNG script, not Jule's main) 
and wait for stats to be sent to your telegram! :D
