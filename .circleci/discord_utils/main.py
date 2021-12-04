import os
import argparse
import asyncio
from senders.bot_sender import BotSender
from senders.channels_sender import ChannelsSender
from senders.individuals_sender import IndividualsSender
from messages import ci_failure_message, ci_success_message

async def send(bot, message):
    await bot.login()
    if args.individuals:
        sender = IndividualsSender(bot)
        await sender.sendMessage(message, args.individuals[0].split(','))
    if args.channels:
        sender = ChannelsSender(bot)
        await sender.sendMessage(message, args.channels[0].split(','))
    await bot.close()

parser = argparse.ArgumentParser()
parser.add_argument('command')
parser.add_argument('--individuals', '-i', help='Individuals(s) to whom the report will be Send', nargs=1)
parser.add_argument('--channels', '-c', help='Channel(s) to which the report will be Send', nargs=1)
args = parser.parse_args()

commands = {
    'report_ci_failure': ci_failure_message(),
    'report_ci_Success': ci_success_message()
}

bot_token = os.getenv('DISCORD_BOT_TOKEN')
guild_id = os.getenv('DISCORD_GUILD_ID')

if not args.command in commands:
    print('nop')
    exit(1)

c = commands[args.command]
print(c)
bot = BotSender(token=bot_token, guild_id=guild_id)
asyncio.run(send(bot, c))
