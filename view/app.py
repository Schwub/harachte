from flask import Flask, render_template
import sys
import os
sys.path.append('../model')
os.chdir("../model")
from model import MODEL
os.chdir("../view")

def create_app():
    app = Flask(__name__)
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/connect')
    def connect():
        return render_template('connect.html', model = MODEL)

    @app.route('/test')
    def test():
        return render_template('test.html')

    @app.route('/calibrate')
    def calibrate():
        return render_template('calibrate.html')

    @app.route('/scan')
    def scan():
        return render_template('scan.html')

    return app



if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)
