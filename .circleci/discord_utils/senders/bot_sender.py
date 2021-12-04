import discord
from discord.ext import commands
from abc import abstractmethod

class BotSender:
    def __init__(self, bot_object=None, token=None, guild_id=None):
        if bot_object:
            self.bot = bot_object.bot
            self.guild_id = bot_object.guild_id
        elif token and guild_id:
            self.intents = discord.Intents.default()
            self.intents.members = True
            self.bot = commands.Bot(command_prefix='>', intents=self.intents)
            self.token = token
            self.guild_id = guild_id
        else:
            raise Exception("Wrong Or Empty Parameters!")

    async def login(self):
        await self.bot.login(self.token)

    @abstractmethod
    async def sendMessage(self, recipients):
        pass

    async def close(self):
        await self.bot.close()