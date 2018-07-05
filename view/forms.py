from flask_wtf import FlaskForm
from wtforms import StringField, BooleanField, SubmitField
from wtforms.validators import DataRequired

class ConnectBoardForm(FlaskForm):
    serialname = StringField("Serialname", validators=[DataRequired()], default="/dev/ttyUSB0")
    baudrate = StringField("Baudrate", validators=[DataRequired()], default="115200")
    submit = SubmitField("Connect")

class DisconnectBoardForm(FlaskForm):
    submit = SubmitField("Disconnect")
