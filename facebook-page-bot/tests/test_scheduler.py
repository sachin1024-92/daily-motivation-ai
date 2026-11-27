from datetime import datetime

from bot.scheduler import State, due_now


def at(h, m=0):
    return datetime(2026, 1, 1, h, m)


def test_nothing_before_window():
    assert due_now(20, 0, at(6), 7, 23) == 0


def test_spreads_evenly():
    # first hour of a 16-hour window: ceil(20 * 1/16) = 2
    assert due_now(20, 0, at(7), 7, 23) == 2
    # halfway: ceil(20 * 9/16) = 12, already posted 10 -> 2 more
    assert due_now(20, 10, at(15), 7, 23) == 2


def test_full_quota_by_end_and_never_negative():
    assert due_now(20, 0, at(23), 7, 23) == 20
    assert due_now(5, 9, at(23), 7, 23) == 0


def test_state_resets_daily(tmp_path):
    s = State(tmp_path / "s.json")
    s.record("comedy", "2026-01-01", "k1", "p1")
    assert s.page("comedy", "2026-01-01")["posted_today"] == 1
    s.save()
    s2 = State(tmp_path / "s.json")
    p = s2.page("comedy", "2026-01-02")
    assert p["posted_today"] == 0 and p["seen"] == ["k1"]
