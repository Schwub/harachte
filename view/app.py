from flask import Flask, render_template, flash
import sys
import os
sys.path.append('../model')
os.chdir("../model")
from model import MODEL
os.chdir("../view")
from forms import ConnectBoardForm, DisconnectBoardForm

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'key'
    @app.route('/')
    def index():
        return render_template('index.html')

    @app.route('/connect', methods=["GET", "POST"])
    def connect():
        connectBoardForm = ConnectBoardForm()
        disconnectBoardForm = DisconnectBoardForm()
        if connectBoardForm.validate_on_submit():
            flash("Connecting to Board")
            MODEL["board"]["connected"] = True
            flash("Success connecting to Board")
        if disconnectBoardForm.validate_on_submit():
            flash("Disconnecting from Board")
            MODEL["board"]["connected"] = False
            flash("Success disconnecting from Board")
        return render_template('connect.html', model=MODEL, connectBoardForm=connectBoardForm, disconnectBoardForm=disconnectBoardForm)

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
