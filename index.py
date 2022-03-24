from flask import Flask


app = Flask('_name_')


@app.route('/')
def index():
    return "<p>This is the index page.</p>"