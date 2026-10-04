import csv
from pathlib import Path

CSV_PATH = Path(__file__).parents[1] / 'Resources' / 'Locale' / 'locale.csv'

def test_arabic_column_is_complete_and_has_arabic_script():
    rows = list(csv.reader(CSV_PATH.open(encoding='utf-8-sig', newline='')))
    header = rows[0]
    assert 'ar' in header
    ar = header.index('ar')
    keys = [row[0] for row in rows[1:] if row and row[0]]
    assert len(keys) == len(set(keys))
    values = [row[ar].strip() for row in rows[1:] if row and row[0]]
    assert all(values)
    assert sum(any('\u0600' <= ch <= '\u06ff' for ch in value) for value in values) >= len(values) * 0.9

if __name__ == "__main__":
    test_arabic_column_is_complete_and_has_arabic_script()
    print("PASS: Arabic localization test")
