import name


def test_hello(capsys):
    name.hello()
    captured = capsys.readouterr()
    assert captured.out == "Hello from testing!\n"
    assert captured.err == ""
