import os
import sqlite3
import pandas as pd
from datetime import datetime
from logger_config import get_logger

logger = get_logger('aegis_monitor')

# Database connection helper
def get_db_connection():
    db_path = os.getenv('SQLITE_DB_PATH', os.path.join(os.path.dirname(__file__), 'snowball.db'))
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn

class AegisMonitorEngine:
    """
    Aegis Monitoring Engine
    Focuses on 4 major populations: Access, Change, Batch, Interface.
    """
    
    def __init__(self):
        self.log_prefix = "[Aegis Engine]"

    def extract_populations(self):
        """
        Step 1: Extract populations from In-Scope systems.
        In this prototype, we simulate extraction from existing tables or mock sources.
        """
        logger.info(f"{self.log_prefix} Starting population extraction...")
        # Mocking 4 populations
        populations = {
            'UserAccess': self._mock_extract_access(),
            'ProgramChange': self._mock_extract_changes(),
            'BatchJob': self._mock_extract_batch(),
            'Interface': self._mock_extract_interface()
        }
        return populations

    def match_with_csr(self, populations):
        """
        Step 2: Match extracted populations with CSR (Change Service Request) approvals.
        """
        logger.info(f"{self.log_prefix} Matching populations with CSR approvals...")
        results = {}
        for category, data in populations.items():
            # Matching logic here (Simulated)
            matched_count = 0
            unmapped_count = 0
            
            # Simple simulation: 90% match rate
            import random
            for item in data:
                if random.random() > 0.1:
                    matched_count += 1
                else:
                    unmapped_count += 1
            
            results[category] = {
                'total': len(data),
                'matched': matched_count,
                'unmapped': unmapped_count,
                'status': 'PASS' if unmapped_count == 0 else 'WARNING'
            }
        return results

    def run_cycle(self):
        """
        Complete monitoring cycle.
        """
        try:
            pops = self.extract_populations()
            matches = self.match_with_csr(pops)
            self._save_results(matches)
            logger.info(f"{self.log_prefix} Monitoring cycle completed successfully.")
            return matches
        except Exception as e:
            logger.error(f"{self.log_prefix} Error during monitoring cycle: {str(e)}")
            return None

    def _save_results(self, results):
        """Save results to aegis_monitor_log table"""
        conn = get_db_connection()
        try:
            now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            for category, data in results.items():
                conn.execute('''
                    INSERT INTO aegis_monitor_log (category, total_count, match_count, unmapped_count, status, log_date)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (category, data['total'], data['matched'], data['unmapped'], data['status'], now))
            conn.commit()
        finally:
            conn.close()

    # --- Mock Extractors ---
    def _mock_extract_access(self):
        return [{'user': 'admin', 'action': 'GRANT', 'time': '2026-04-19 10:00:00'}] * 10
    
    def _mock_extract_changes(self):
        return [{'file': 'snowball.py', 'commit': 'abc123', 'time': '2026-04-19 11:00:00'}] * 5
    
    def _mock_extract_batch(self):
        return [{'job': 'daily_backup', 'status': 'SUCCESS', 'time': '2026-04-19 02:00:00'}] * 2
    
    def _mock_extract_interface(self):
        return [{'if_id': 'IF001', 'rows': 1000, 'time': '2026-04-19 09:00:00'}] * 3

if __name__ == "__main__":
    engine = AegisMonitorEngine()
    engine.run_cycle()
