from flask import Blueprint, render_template

# Create blueprint for main dashboard
dashboard_bp = Blueprint('dashboard', __name__)

def load_schemas():
    """Load schemas for the dashboard"""
    from app import load_schemas
    return load_schemas()

@dashboard_bp.route('/')
def dashboard():
    """Main dashboard page with navigation to other routes"""
    from app import connection_status, connection_lock
    
    schemas = load_schemas()
    with connection_lock:
        status = connection_status.copy()
    
    return render_template('dashboard.html', 
                         schemas=schemas, 
                         connection_status=status)
