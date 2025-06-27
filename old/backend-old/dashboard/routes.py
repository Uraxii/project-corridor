# routes.py

from dashboard import dashboard_bp
from entity import entity_bp
from message_tester import message_tester_bp

def register_blueprints(app):
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(entity_bp)
    app.register_blueprint(message_tester_bp)
