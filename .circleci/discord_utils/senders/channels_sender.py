from .bot_sender import BotSender
import discord
from datetime import datetime

class ChannelsSender(BotSender):
    async def sendMessage(self, message, channels):
        a = await self.bot.fetch_guild(self.guild_id)
        guild_channels = await a.fetch_channels()
        for guild_channel in guild_channels:
            if guild_channel.name in channels:
                await guild_channel.send(embed=discord.Embed(title=message["title"], description=message["description"], url=message["url"], timestamp=datetime.now(), color=discord.Colour(message["color"])))