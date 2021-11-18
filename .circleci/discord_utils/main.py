import argparse
from messages import ci_failure_message, ci_success_message

parser = argparse.ArgumentParser()
parser.add_argument('command')
parser.add_argument('--individuals', '-i', help='Individuals(s) to whom the report will be Send', nargs=1)
parser.add_argument('--channels', '-c', help='Channel(s) to which the report will be Send', nargs=1)
args = parser.parse_args()

commands = {
    'report_ci_failure': ci_failure_message(),
    'report_ci_Success': ci_success_message()
}

if not args.command in commands:
    exit(1)

c = commands[args.command]
if args.individuals:
    # send each individual the message printed at the end
    print(f"Individual(s) are: {args.individuals[0].split(',')}")
if args.channels:
    # send each channel the message printed at the end
    print(f"Channel(s) are: {args.channels[0].split(',')}")

print(c)