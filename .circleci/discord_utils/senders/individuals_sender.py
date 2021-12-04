from .bot_sender import BotSender
import discord
from datetime import datetime

class IndividualsSender(BotSender):
    async def sendMessage(self, message, users):
        a = await self.bot.fetch_guild(self.guild_id)
        async for member in a.fetch_members():
            if member.display_name in users:
                await member.send(embed=discord.Embed(title=message["title"], description=message["description"], url=message["url"], timestamp=datetime.now(), color=discord.Colour(message["color"])))