# routes/__init__.py
from flask import Flask

def register_blueprints(app: Flask):
    """Register all route blueprints with the Flask app"""
    
    # Import blueprints
    from .dashboard import dashboard_bp
    from .entity import entity_bp
    from .message_tester import message_tester_bp
    
    # Register blueprints
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(entity_bp)
    app.register_blueprint(message_tester_bp)
    
    return app
