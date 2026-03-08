#!/usr/bin/env python3
"""
Database Management CLI
Usage:
  python manage_db.py seed          - Seed database with sample data
  python manage_db.py verify        - Verify database connection
  python manage_db.py stats         - Show data statistics
  python manage_db.py clear         - Clear all data (WARNING: destructive)
"""

import sys
import argparse
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent / "backend"))

def verify_connection():
    """Verify database connection."""
    try:
        from database import get_db_session
        session = get_db_session()
        session.execute("SELECT 1")
        session.close()
        print("✅ Database connection successful")
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False

def show_stats():
    """Show database statistics."""
    try:
        from database import get_db_session
        from sqlalchemy import text
        
        session = get_db_session()
        
        stats = session.execute(text("""
            SELECT
                (SELECT COUNT(*) FROM pipelines_systems) as systems,
                (SELECT COUNT(*) FROM pipelines_routes) as routes,
                (SELECT COUNT(*) FROM pipelines_segments) as segments,
                (SELECT COUNT(*) FROM pipelines_stations) as stations,
                (SELECT COUNT(*) FROM pipelines_valves) as valves,
                (SELECT COUNT(*) FROM pipelines_inline_devices) as devices
        """)).first()
        
        print("\n📊 Database Statistics:")
        print(f"  Systems:  {stats.systems}")
        print(f"  Routes:   {stats.routes}")
        print(f"  Segments: {stats.segments}")
        print(f"  Stations: {stats.stations}")
        print(f"  Valves:   {stats.valves}")
        print(f"  Devices:  {stats.devices}")
        print(f"  Total:    {sum(stats)}")
        
        # Show systems overview
        systems = session.execute(text("""
            SELECT name, operator_name, product, region, COUNT(routes.id) as route_count
            FROM pipelines_systems
            LEFT JOIN pipelines_routes as routes ON routes.system_id = pipelines_systems.id
            GROUP BY pipelines_systems.id, name, operator_name, product, region
            ORDER BY name
        """)).fetchall()
        
        if systems:
            print("\n🏢 Pipeline Systems:")
            for sys in systems:
                print(f"  • {sys.name} ({sys.operator_name})")
                print(f"    Product: {sys.product} | Region: {sys.region} | Routes: {sys.route_count}")
        
        session.close()
    except Exception as e:
        print(f"❌ Error fetching statistics: {e}")

def seed_data():
    """Seed database with sample data."""
    try:
        from seed_data import seed_database
        print("🌱 Seeding database...")
        seed_database()
        print("\n✅ Database seeding completed!\n")
        show_stats()
    except Exception as e:
        print(f"❌ Error seeding database: {e}")
        sys.exit(1)

def clear_data():
    """Clear all data from database (WARNING: destructive)."""
    confirm = input("⚠️  WARNING: This will delete ALL data. Type 'yes' to confirm: ")
    if confirm.lower() != 'yes':
        print("Cancelled.")
        return
    
    try:
        from database import get_db_session
        from sqlalchemy import text
        
        session = get_db_session()
        
        print("🗑️  Clearing data...")
        session.execute(text("DELETE FROM pipelines_inline_devices;"))
        session.execute(text("DELETE FROM pipelines_valves;"))
        session.execute(text("DELETE FROM pipelines_stations;"))
        session.execute(text("DELETE FROM pipelines_segments;"))
        session.execute(text("DELETE FROM pipelines_routes;"))
        session.execute(text("DELETE FROM pipelines_systems;"))
        session.commit()
        
        print("✅ All data cleared.\n")
        show_stats()
        session.close()
    except Exception as e:
        print(f"❌ Error clearing data: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Pipeline Database Management")
    parser.add_argument("action", choices=["seed", "verify", "stats", "clear"],
                       help="Action to perform")
    
    args = parser.parse_args()
    
    if args.action == "verify":
        verify_connection()
    elif args.action == "stats":
        show_stats()
    elif args.action == "seed":
        seed_data()
    elif args.action == "clear":
        clear_data()

if __name__ == "__main__":
    main()
