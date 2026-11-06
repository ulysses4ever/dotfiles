#!/usr/bin/env python3
"""Make the showroom's books: a fictional household's journal, eighteen
months of it up to today, so that the month view always has something to
show. The same seed gives the same history; only the end moves. The cards
are paid off on the 25th, whatever they ran up, so the balances stay the
size a household's are.

Usage: showroom-sample.py OUT.journal [--today YYYY-MM-DD]
"""
import argparse, calendar, random
from datetime import date, timedelta

ACCOUNTS = [
    ('assets', 'A'), ('liabilities', 'L'), ('equity', 'E'), ('income', 'R'), ('expenses', 'X'),
    ('assets:bank:checking', None), ('assets:bank:savings', None), ('assets:cash', None),
    ('liabilities:card:visa', None), ('liabilities:card:store', None),
    ('equity:opening', None),
    ('income:salary', None), ('income:interest', None), ('income:gifts', None),
    ('expenses:food:groceries', None), ('expenses:food:dining', None), ('expenses:food:coffee', None),
    ('expenses:housing:rent', None), ('expenses:utilities:power', None), ('expenses:utilities:internet', None),
    ('expenses:utilities:phone', None), ('expenses:car:fuel', None), ('expenses:car:parking', None),
    ('expenses:health:pharmacy', None), ('expenses:health:doctor', None), ('expenses:child:toys', None),
    ('expenses:child:clothes', None), ('expenses:household:supplies', None), ('expenses:shopping:clothing', None),
    ('expenses:shopping:gifts', None), ('expenses:entertainment:streaming', None), ('expenses:entertainment:outings', None),
    ('expenses:entertainment:gym', None), ('expenses:social:charity', None), ('expenses:travel', None),
]

# the shops: (payee, account, typical amount, spread, how often per month, the card paid with)
SHOPS = [
    ('Green Grocer', 'expenses:food:groceries', 68, 30, 9, 'visa'),
    ('Corner Market', 'expenses:food:groceries', 24, 12, 4, 'visa'),
    ('Bean There', 'expenses:food:coffee', 5.25, 2, 10, 'visa'),
    ('Luna Trattoria', 'expenses:food:dining', 54, 20, 2, 'visa'),
    ('Taco Garden', 'expenses:food:dining', 23, 8, 3, 'visa'),
    ('Riverside Fuel', 'expenses:car:fuel', 46, 12, 3, 'visa'),
    ('City Parking', 'expenses:car:parking', 3.5, 2, 4, 'visa'),
    ('Maple Pharmacy', 'expenses:health:pharmacy', 18, 10, 2, 'visa'),
    ('Little Hands Toys', 'expenses:child:toys', 27, 14, 1, 'store'),
    ('Kidwear Outlet', 'expenses:child:clothes', 35, 15, 1, 'store'),
    ('Everything Store', 'expenses:household:supplies', 31, 20, 4, 'store'),
    ('Thread & Needle', 'expenses:shopping:clothing', 58, 30, 1, 'store'),
    ('Paperback Row', 'expenses:shopping:gifts', 22, 10, 1, 'visa'),
    ('Pine Hill Park', 'expenses:entertainment:outings', 15, 10, 1, 'visa'),
]
NOTES = {
    'Green Grocer': ['weekly shop', 'fruit and bread', '', '', ''],
    'Luna Trattoria': ['date night', 'with the Novaks', ''],
    'Everything Store': ['light bulbs', 'kitchen roll', 'batteries', ''],
    'Little Hands Toys': ['birthday present', 'puzzle'],
    'Paperback Row': ['for mum', 'for Lena'],
    'Pine Hill Park': ['zoo day', 'boat hire'],
}
CARD = {'visa': 'liabilities:card:visa', 'store': 'liabilities:card:store'}


def money(x):
    return f'${x:,.2f}' if x >= 0 else f'$-{-x:,.2f}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('--today')
    a = ap.parse_args()
    today = date.fromisoformat(a.today) if a.today else date.today()
    rng = random.Random(20261103)
    start = (today.replace(day=1) - timedelta(days=17 * 30)).replace(day=1)
    end = today + timedelta(days=calendar.monthrange(today.year, today.month)[1] - today.day)  # end of this month
    future = lambda d: d > today
    st = lambda d: '!' if future(d) else '*'

    # Each entry: date, status, description, comment, postings as (account,
    # text), and what it puts on a card (name, dollars), or the card it pays.
    entries = []

    def add(d, desc, postings, status='', comment='', card=None, pays=None):
        entries.append({'d': d, 'desc': desc, 'postings': postings, 'status': status, 'comment': comment, 'card': card, 'pays': pays})

    def charge(d, desc, acct, amt, card, status='', comment=''):
        add(d, desc, [(acct, money(amt)), (CARD[card], '')], status, comment, card=(card, -amt))

    add(start, 'Opening balances', [('assets:bank:checking', money(2450)), ('assets:bank:savings', money(8000)),
                                    ('assets:cash', money(120)), ('liabilities:card:visa', money(-312.40)), ('equity:opening', '')],
        '*', card=('visa', -312.40))
    m = start
    while m <= end:
        last = calendar.monthrange(m.year, m.month)[1]
        day = lambda n: m.replace(day=min(n, last))
        # the fixed lines; the rest of this month's are written ahead, pending
        add(day(1), 'Hillside Properties | rent', [('expenses:housing:rent', money(1650)), ('assets:bank:checking', '')], st(day(1)), 'recurring:1')
        for n in (1, 15):
            add(day(n), 'Acme Robotics | salary', [('assets:bank:checking', money(2150)), ('income:salary', '')], st(day(n)), 'recurring:2')
        add(day(6), 'Northwind Power', [('expenses:utilities:power', money(round(rng.uniform(70, 140), 2))), ('assets:bank:checking', '')], st(day(6)), 'recurring:3')
        charge(day(12), 'Fibre Fast', 'expenses:utilities:internet', 59.99, 'visa', st(day(12)), 'recurring:4')
        charge(day(18), 'Wavelength Mobile', 'expenses:utilities:phone', 45, 'visa', st(day(18)), 'recurring:5')
        charge(day(9), 'Streamly', 'expenses:entertainment:streaming', 12.99, 'visa', st(day(9)), 'recurring:6')
        charge(day(3), 'Iron Works Gym', 'expenses:entertainment:gym', 39, 'visa', st(day(3)), 'recurring:7')
        # a gift in euros, at what the card charged for it
        eur = round(25 * rng.uniform(1.06, 1.12), 2)
        add(day(20), 'Open Shelter | monthly gift', [('expenses:social:charity', f'25.00 EUR @@ {money(eur)}'), ('liabilities:card:visa', money(-eur))],
            st(day(20)), 'recurring:8', card=('visa', -eur))
        add(day(28), 'First Trust Bank | interest', [('assets:bank:savings', money(round(8000 * 0.035 / 12, 2))), ('income:interest', '')], st(day(28)), 'recurring:9')
        add(day(16), 'To savings', [('assets:bank:savings', money(300)), ('assets:bank:checking', '')], st(day(16)))
        # the cards paid off on the 25th and 26th: how much is worked out below
        add(day(25), 'Visa card payment', [], st(day(25)), pays='visa')
        add(day(26), 'Store card payment', [], st(day(26)), pays='store')
        # the shops, on days up to today only
        for payee, acct, typical, spread, permonth, card in SHOPS:
            n = max(0, round(rng.gauss(permonth, permonth / 3)))
            for _ in range(n):
                d = day(rng.randint(1, last))
                if future(d):
                    continue
                amt = max(1.5, round(rng.gauss(typical, spread / 2), 2))
                note = rng.choice(NOTES.get(payee, ['']))
                charge(d, f'{payee} | {note}' if note else payee, acct, amt, card)
        # now and then: cash, the doctor, a present, a trip
        if rng.random() < 0.6:
            d = day(rng.randint(2, last - 8))
            if not future(d):
                add(d, 'Cash withdrawal', [('assets:cash', money(100)), ('assets:bank:checking', '')])
                for k, (payee, acct, lo, hi) in enumerate([('Farmers market', 'expenses:food:groceries', 18, 42), ('Bean There', 'expenses:food:coffee', 4, 9),
                                                           ('City Parking', 'expenses:car:parking', 2, 6), ('Corner Market', 'expenses:food:groceries', 8, 25)]):
                    d2 = d + timedelta(days=k * 2 + 1)
                    if not future(d2):
                        add(d2, payee, [(acct, money(round(rng.uniform(lo, hi), 2))), ('assets:cash', '')])
        if rng.random() < 0.3:
            d = day(rng.randint(2, last))
            if not future(d):
                charge(d, 'Dr Okafor | check-up', 'expenses:health:doctor', rng.choice([40, 75, 120]), 'visa')
        if m.month in (5, 12) and not future(day(14)):
            add(day(14), 'Aunt Vera | birthday money', [('assets:bank:checking', money(100)), ('income:gifts', '')])
        if m.month in (7, 12) and not future(day(21)):
            charge(day(21), 'Skyline Air | flights', 'expenses:travel', round(rng.uniform(380, 640), 2), 'visa')
            charge(day(23), 'Harbour Hotel | three nights', 'expenses:travel', round(rng.uniform(420, 560), 2), 'visa')
        m = (m.replace(day=1) + timedelta(days=32)).replace(day=1)

    # The card payments: each pays what its card has run up by then.
    entries.sort(key=lambda e: e['d'])
    balance = {'visa': 0.0, 'store': 0.0}
    kept = []
    for e in entries:
        if e['card']:
            balance[e['card'][0]] += e['card'][1]
        if e['pays']:
            owed = round(-balance[e['pays']], 2)
            if owed <= 0:
                continue
            e['postings'] = [(CARD[e['pays']], money(owed)), ('assets:bank:checking', '')]
            balance[e['pays']] = 0.0
        kept.append(e)

    def render(e):
        head = f"{e['d']} {e['status'] + ' ' if e['status'] else ''}{e['desc']}".rstrip() + (f"  ; {e['comment']}" if e['comment'] else '')
        width = max(len(acct) for acct, _ in e['postings']) + 4
        return '\n'.join([head] + [f'    {acct:<{width}}{amt:>12}' if amt else f'    {acct}' for acct, amt in e['postings']])

    out = ['; The showroom\'s books: a fictional household, made up by showroom-sample.py.\n',
           'commodity $1,000.00\ncommodity 1,000.00 EUR\nD $1,000.00\n']
    out += [f'account {name}' + (f'  ; type: {ty}' if ty else '') for name, ty in ACCOUNTS] + ['']
    payees = sorted({s[0] for s in SHOPS} | {'Acme Robotics', 'Hillside Properties', 'Northwind Power', 'Fibre Fast',
                    'Wavelength Mobile', 'Streamly', 'Iron Works Gym', 'Open Shelter', 'First Trust Bank', 'Aunt Vera',
                    'Dr Okafor', 'Harbour Hotel', 'Skyline Air', 'Farmers market'}, key=str.lower)
    out += [f'payee {p}' for p in payees] + ['']
    # the rules the fixed lines come from, as the Recurring page shows them
    first = (today.replace(day=1) - timedelta(days=1)).replace(day=1)   # from last month
    def rule(n, expr, desc, acct, amt, other):
        return f'~ {expr}  {desc}  ; recurring:{n}\n    {acct:<36}{amt:>12}\n    {other}\n'
    out += [
        rule(1, f'monthly from {first}', 'Hillside Properties | rent', 'expenses:housing:rent', money(1650), 'assets:bank:checking'),
        rule(2, f'every 2 weeks from {first}', 'Acme Robotics | salary', 'assets:bank:checking', money(2150), 'income:salary'),
        rule(3, f'monthly from {first.replace(day=6)}', 'Northwind Power', 'expenses:utilities:power', money(105), 'assets:bank:checking'),
        rule(4, f'monthly from {first.replace(day=12)}', 'Fibre Fast', 'expenses:utilities:internet', money(59.99), 'liabilities:card:visa'),
        rule(5, f'monthly from {first.replace(day=18)}', 'Wavelength Mobile', 'expenses:utilities:phone', money(45), 'liabilities:card:visa'),
        rule(6, f'monthly from {first.replace(day=9)}', 'Streamly', 'expenses:entertainment:streaming', money(12.99), 'liabilities:card:visa'),
        rule(7, f'monthly from {first.replace(day=3)}', 'Iron Works Gym', 'expenses:entertainment:gym', money(39), 'liabilities:card:visa'),
        rule(8, f'monthly from {first.replace(day=20)}', 'Open Shelter | monthly gift', 'expenses:social:charity', '25.00 EUR', 'liabilities:card:visa'),
        rule(9, f'monthly from {first.replace(day=16)}', 'To savings', 'assets:bank:savings', money(300), 'assets:bank:checking'),
    ]
    out.append('\n\n'.join(render(e) for e in kept) + '\n')
    open(a.out, 'w', encoding='utf-8').write('\n'.join(out))
    print(f'{len(kept)} entries, {start} .. {end}, written to {a.out}')


if __name__ == '__main__':
    main()
